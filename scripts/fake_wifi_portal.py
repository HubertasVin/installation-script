#!/usr/bin/env python3
"""Fake Wi-Fi captive portal demo.

Creates an open access point; clients that connect are redirected to a page
about the dangers of free Wi-Fi. Requires root, hostapd and dnsmasq.

By default your own Wi-Fi stays connected: the AP runs on a virtual interface
sharing your network's channel. Most cards forbid AP mode on 5 GHz, so if you
are on 5 GHz the script first moves your connection to 2.4 GHz (and restores
the band setting on shutdown). Use --takeover to run the AP on the main
interface instead; this disconnects your Wi-Fi until shutdown.
Ctrl+C shuts down and restores the previous network state.
"""

import argparse
import os
import shutil
import signal
import string
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

GATEWAY = "192.168.53.1"
DHCP_RANGE = "192.168.53.10,192.168.53.100,12h"
PORTAL_URL = f"http://{GATEWAY}/"

shutdown_event = threading.Event()
# Connection profile / band setting captured at startup so shutdown can
# restore exactly what was running.
saved_profile: dict[str, str | None] = {}
saved_band: dict[str, str] = {}

# Page text per language; auto-selected per client from Accept-Language, or forced with --language.
TRANSLATIONS: dict[str, dict[str, str]] = {
    "en": {
        "title": "STOP - Read This Now",
        "banner": "THIS IS A FAKE NETWORK!",
        "sub": "You just joined a network that could be a trap. This time it wasn't.",
        "risks_heading": "What could happen to you here",
        "risk1": "<strong>Someone can read what you send.</strong> Passwords. Messages. Photos. Everything.",
        "risk2": "<strong>Someone can take over your accounts.</strong> They grab your login cookies and walk right in.",
        "risk3": "<strong>You can be tricked into installing a virus.</strong> One fake &ldquo;update&rdquo; is all it takes.",
        "tips_heading": "Do this now",
        "tip1": "Don't log in to anything on public Wi-Fi. Not your bank. Not your email.",
        "tip2": "Don't type passwords.",
        "tip3": "Use your mobile internet instead. It's safer.",
        "tip4": "<strong>Forget this network</strong> so your phone doesn't join it again.",
        "note": "This was a demonstration. Nothing was stolen &mdash; this time. Stay alert.",
    },
    "lt": {
        "title": "STOP - Skaityk dabar",
        "banner": "TAI NETIKRAS TINKLAS!",
        "sub": "Ką tik prisijungėte prie tinklo, kuris gali būti spąstai. Šįkart - ne.",
        "risks_heading": "Kas čia gali atsitikti",
        "risk1": "<strong>Kažkas gali skaityti, ką siunčiate.</strong> Slaptažodžiai. Žinutės. Nuotraukos. Viskas.",
        "risk2": "<strong>Kažkas gali perimti jūsų paskyras.</strong> Jie pavogia jūsų prisijungimo slapukus ir tiesiog įeina.",
        "risk3": "<strong>Galite būti apgauti įdiegti virusą.</strong> Vienas netikras &ldquo;atnaujinimas&rdquo; - ir tiek.",
        "tips_heading": "Darykite tai dabar",
        "tip1": "Nesijunkite prie nieko viešame Wi-Fi tinkle. Ne prie banko. Ne prie el. pašto.",
        "tip2": "Nerašykite slaptažodžių.",
        "tip3": "Naudokite mobilųjį internetą. Jis saugesnis.",
        "tip4": "<strong>Užmirškite šį tinklą</strong>, kad telefonas vėl prie jo neprisijungtų.",
        "note": "Tai buvo demonstracija. Niekas nepavogta - šįkart. Būkite budrūs.",
    },
    "de": {
        "title": "STOPP - Lesen Sie jetzt",
        "banner": "DAS IST EIN FALSCHES NETZWERK!",
        "sub": "Sie haben sich gerade mit einem Netzwerk verbunden, das eine Falle sein könnte. Diesmal nicht.",
        "risks_heading": "Was hier passieren könnte",
        "risk1": "<strong>Jemand kann mitlesen, was Sie senden.</strong> Passwörter. Nachrichten. Fotos. Alles.",
        "risk2": "<strong>Jemand kann Ihre Konten übernehmen.</strong> Er stiehlt Ihre Login-Cookies und geht einfach hinein.",
        "risk3": "<strong>Sie können hereingelegt werden, einen Virus zu installieren.</strong> Ein gefälschtes &ldquo;Update&rdquo; genügt.",
        "tips_heading": "Tun Sie jetzt dies",
        "tip1": "Melden Sie sich im öffentlichen WLAN nirgends an. Nicht bei der Bank. Nicht beim E-Mail.",
        "tip2": "Geben Sie keine Passwörter ein.",
        "tip3": "Nutzen Sie stattdessen Ihr mobiles Internet. Das ist sicherer.",
        "tip4": "<strong>Vergessen Sie dieses Netzwerk</strong>, damit sich Ihr Telefon nicht wieder verbindet.",
        "note": "Dies war eine Demonstration. Diesmal wurde nichts gestohlen. Bleiben Sie wachsam.",
    },
    "fr": {
        "title": "STOP - Lisez ceci maintenant",
        "banner": "CECI EST UN FAUX RÉSEAU !",
        "sub": "Vous venez de rejoindre un réseau qui pourrait être un piège. Pas cette fois.",
        "risks_heading": "Ce qui pourrait vous arriver ici",
        "risk1": "<strong>Quelqu'un peut lire ce que vous envoyez.</strong> Mots de passe. Messages. Photos. Tout.",
        "risk2": "<strong>Quelqu'un peut prendre le contrôle de vos comptes.</strong> Il vole vos cookies de connexion et entre directement.",
        "risk3": "<strong>On peut vous tromper pour installer un virus.</strong> Une fausse &ldquo;mise à jour&rdquo; suffit.",
        "tips_heading": "Faites ceci maintenant",
        "tip1": "Ne connectez-vous à rien sur le Wi-Fi public. Ni banque, ni e-mail.",
        "tip2": "Ne tapez pas de mots de passe.",
        "tip3": "Utilisez plutôt votre internet mobile. C'est plus sûr.",
        "tip4": "<strong>Oubliez ce réseau</strong> pour que votre téléphone ne s'y reconnecte pas.",
        "note": "C'était une démonstration. Rien n'a été volé &mdash; cette fois. Restez vigilant.",
    },
    "es": {
        "title": "ALTO - Lee esto ahora",
        "banner": "¡ESTA ES UNA RED FALSA!",
        "sub": "Acabas de conectarte a una red que podría ser una trampa. Esta vez no.",
        "risks_heading": "Lo que podría pasarte aquí",
        "risk1": "<strong>Alguien puede leer lo que envías.</strong> Contraseñas. Mensajes. Fotos. Todo.",
        "risk2": "<strong>Alguien puede tomar el control de tus cuentas.</strong> Roban tus cookies de inicio de sesión y entran directamente.",
        "risk3": "<strong>Pueden engañarte para instalar un virus.</strong> Basta una falsa &ldquo;actualización&rdquo;.",
        "tips_heading": "Haz esto ahora",
        "tip1": "No inicies sesión en nada en el Wi-Fi público. Ni en tu banco. Ni en tu correo.",
        "tip2": "No escribas contraseñas.",
        "tip3": "Usa mejor tu internet móvil. Es más seguro.",
        "tip4": "<strong>Olvida esta red</strong> para que tu teléfono no se vuelva a conectar.",
        "note": "Esto fue una demostración. No se robó nada &mdash; esta vez. Mantente alerta.",
    },
    "pl": {
        "title": "STOP - Przeczytaj to teraz",
        "banner": "TO SIEĆ JEST FAŁSZYWA!",
        "sub": "Właśnie połączyłeś się z siecią, która może być pułapką. Tym razem nie.",
        "risks_heading": "Co może ci się tu przydarzyć",
        "risk1": "<strong>Ktoś może czytać, co wysyłasz.</strong> Hasła. Wiadomości. Zdjęcia. Wszystko.",
        "risk2": "<strong>Ktoś może przejąć twoje konta.</strong> Kradnie twoje ciasteczka logowania i po prostu wchodzi.",
        "risk3": "<strong>Możesz zostać oszukany i zainstalować wirusa.</strong> Wystarczy jedno fałszywe &ldquo;aktualizacja&rdquo;.",
        "tips_heading": "Zrób to teraz",
        "tip1": "Nie loguj się nigdzie w publicznym Wi-Fi. Ani do banku. Ani do poczty.",
        "tip2": "Nie wpisuj haseł.",
        "tip3": "Użyj raczej internetu mobilnego. Jest bezpieczniejszy.",
        "tip4": "<strong>Zapomnij tę sieć</strong>, żeby telefon nie połączył się ponownie.",
        "note": "To była demonstracja. Tym razem nic nie ukradziono. Bądź czujny.",
    },
    "ru": {
        "title": "СТОП - Прочтите это сейчас",
        "banner": "ЭТО ФАЛЬШИВАЯ СЕТЬ!",
        "sub": "Вы только что подключились к сети, которая может быть ловушкой. В этот раз — нет.",
        "risks_heading": "Что здесь может с вами случиться",
        "risk1": "<strong>Кто-то может читать то, что вы отправляете.</strong> Пароли. Сообщения. Фото. Всё.",
        "risk2": "<strong>Кто-то может захватить ваши аккаунты.</strong> Он крадёт ваши cookie входа и просто заходит.",
        "risk3": "<strong>Вас могут обмануть, чтобы установить вирус.</strong> Достаточно одного поддельного &ldquo;обновления&rdquo;.",
        "tips_heading": "Сделайте это сейчас",
        "tip1": "Ни во что не входите в публичном Wi-Fi. Ни в банк. Ни в почту.",
        "tip2": "Не вводите пароли.",
        "tip3": "Лучше используйте мобильный интернет. Он безопаснее.",
        "tip4": "<strong>Забудьте эту сеть</strong>, чтобы телефон больше к ней не подключался.",
        "note": "Это была демонстрация. В этот раз ничего не украли. Будьте бдительны.",
    },
    "lv": {
        "title": "STOP - Izlasi to tagad",
        "banner": "ŠIS IR VILTS TĪKLS!",
        "sub": "Jūs tikko pievienojāties tīklam, kas varētu būt lamatas. Šoreiz - ne.",
        "risks_heading": "Kas šeit varētu notikt",
        "risk1": "<strong>Kāds var lasīt to, ko sūtat.</strong> Paroles. Ziņas. Fotogrāfijas. Viss.",
        "risk2": "<strong>Kāds var pārņemt jūsu kontus.</strong> Viņš nozog jūsu pieteikšanās sīkdatnes un vienkārši ieej.",
        "risk3": "<strong>Jūs varētu apmānīt, lai instalētu vīrusu.</strong> Pietiek ar vienu viltoju &ldquo;atjauninājumu&rdquo;.",
        "tips_heading": "Dariet to tagad",
        "tip1": "Nepieslēdzieties nekam publiskajā Wi-Fi tīklā. Ne bankai. Ne e-pastam.",
        "tip2": "Nerakstiet paroles.",
        "tip3": "Labāk izmantojiet mobilo internetu. Tas ir drošāk.",
        "tip4": "<strong>Aizmirstiet šo tīklu</strong>, lai telefons tam vairs nepieslēdzas.",
        "note": "Tā bija demonstrācija. Šoreiz nekas nav nozagts. Esiet uzmanīgi.",
    },
    "et": {
        "title": "STOP - Loe seda kohe",
        "banner": "SEE ON VÕLTSVÕRK!",
        "sub": "Sa ühinesid just võrguga, mis võib olla lõks. Seekord mitte.",
        "risks_heading": "Mis siin võib juhtuda",
        "risk1": "<strong>Keegi võib lugeda, mida saadad.</strong> Paroolid. Sõnumid. Fotod. Kõik.",
        "risk2": "<strong>Keegi võib üle võtta sinu kontod.</strong> Ta varastab sinu sisselogimisküpsised ja lihtsalt siseneb.",
        "risk3": "<strong>Sind võidakse petta viiruse paigaldama.</strong> Piisab ühest võltsitud &ldquo;värskendusest&rdquo;.",
        "tips_heading": "Tee seda kohe",
        "tip1": "Ära logi avalikus Wi-Fi võrgus kuhugi sisse. Mitte panka. Mitte e-posti.",
        "tip2": "Ära kirjuta paroole.",
        "tip3": "Kasuta pigem mobiilset internetti. See on turvalisem.",
        "tip4": "<strong>Unusta see võrk</strong>, et telefon sinna uuesti ei ühineks.",
        "note": "See oli demonstratsioon. Seekord midagi varastatud ei saanud. Ole valvas.",
    },
    "sv": {
        "title": "STOPP - Läs detta nu",
        "banner": "DETTA ÄR ETT FALSKT NÄTVERK!",
        "sub": "Du anslöt just till ett nätverk som kan vara en fälla. Inte den här gången.",
        "risks_heading": "Vad som kan hända dig här",
        "risk1": "<strong>Någon kan läsa det du skickar.</strong> Lösenord. Meddelanden. Bilder. Allt.",
        "risk2": "<strong>Någon kan ta över dina konton.</strong> De stjäl dina inloggningscookies och går bara in.",
        "risk3": "<strong>Du kan luras att installera ett virus.</strong> En enda falsk &ldquo;uppdatering&rdquo; räcker.",
        "tips_heading": "Gör detta nu",
        "tip1": "Logga inte in på något på offentligt Wi-Fi. Inte banken. Inte e-posten.",
        "tip2": "Skriv inte lösenord.",
        "tip3": "Använd hellre ditt mobila internet. Det är säkrare.",
        "tip4": "<strong>Glöm det här nätverket</strong> så att telefonen inte ansluter igen.",
        "note": "Detta var en demonstration. Inget stals &mdash; den här gången. Var vaksam.",
    },
}
DEFAULT_LANG = "en"

PAGE_TEMPLATE = """<!DOCTYPE html>
<html lang="$lang">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<style>
  body { font-family: system-ui, sans-serif; margin: 0; background: #0d0d0f; color: #f2f2f2; }
  .banner { background: #b3001b; text-align: center; padding: 2rem 1rem; }
  .banner .icon { font-size: 3rem; display: block; }
  .banner h1 { font-size: 2rem; margin: .5rem 0 0; letter-spacing: .05em; }
  .wrap { max-width: 620px; margin: 0 auto; padding: 1.5rem 1.25rem 3rem; }
  .sub { text-align: center; font-size: 1.1rem; color: #ffb3b3; margin: 0 0 2rem; }
  h2 { font-size: 1.2rem; color: #ff4d4d; margin: 1.75rem 0 .5rem; }
  ul { margin: .25rem 0; padding-left: 1.25rem; line-height: 1.9; font-size: 1.05rem; }
  .card { background: #17171b; border: 1px solid #3a1015; border-radius: 10px; padding: 1.25rem 1.5rem; }
  .note { margin-top: 2rem; font-size: .9rem; color: #8a8a92; text-align: center; }
  strong { color: #fff; }
</style>
</head>
<body>
<div class="banner">
  <span class="icon">&#9888;</span>
  <h1>$banner</h1>
</div>
<div class="wrap">
  <p class="sub">$sub</p>

  <div class="card">
    <h2>$risks_heading</h2>
    <ul>
      <li>$risk1</li>
      <li>$risk2</li>
      <li>$risk3</li>
    </ul>

    <h2>$tips_heading</h2>
    <ul>
      <li>$tip1</li>
      <li>$tip2</li>
      <li>$tip3</li>
      <li>$tip4</li>
    </ul>
  </div>

  <p class="note">$note</p>
</div>
</body>
</html>
"""


def render_page(lang: str) -> str:
    return string.Template(PAGE_TEMPLATE).substitute(lang=lang, **TRANSLATIONS[lang])


def pick_language(accept_header: str | None, forced: str | None) -> str:
    if forced:
        return forced if forced in TRANSLATIONS else DEFAULT_LANG
    for part in (accept_header or "").split(","):
        code = part.split(";")[0].strip().split("-")[0].lower()
        if code in TRANSLATIONS:
            return code
    return DEFAULT_LANG


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def nmcli(*args: str) -> subprocess.CompletedProcess:
    return run(["nmcli", *args], check=False)


def detect_interface() -> str:
    result = run(["iw", "dev"], check=False)
    for line in result.stdout.splitlines():
        if line.strip().startswith("Interface "):
            return line.split()[1]
    sys.exit("No wireless interface found (iw dev returned nothing).")


def active_profile(interface: str) -> str | None:
    result = nmcli("-t", "-f", "NAME,DEVICE", "connection", "show", "--active")
    for line in result.stdout.splitlines():
        if line.endswith(f":{interface}"):
            return line.rsplit(":", 1)[0]
    return None


def get_freq(interface: str) -> float | None:
    result = run(["iw", "dev", interface, "link"], check=False)
    for line in result.stdout.splitlines():
        if "freq:" in line:
            return float(line.split("freq:")[1].split()[0])
    return None


def freq_to_channel(freq: float) -> int:
    return int((freq - 5000) / 5) if freq > 4000 else int((freq - 2407) / 5)


def reconnect_wifi(interface: str) -> None:
    profile = saved_profile.get(interface)
    result = nmcli("connection", "up", profile, "ifname", interface) if profile else nmcli("device", "connect", interface)
    if result.returncode == 0:
        print(f"Reconnected {interface} via {profile or 'auto-select'}.")
    else:
        print(f"WARNING: could not reconnect {interface}; run: nmcli device connect {interface}", file=sys.stderr)


def restore_band(interface: str) -> None:
    """Undo the temporary 2.4 GHz band switch."""
    profile = saved_profile.get(interface)
    if profile and interface in saved_band:
        nmcli("connection", "modify", profile, "802-11-wireless.band", saved_band.pop(interface))
        print(f"Restored band setting on '{profile}'.")


def ensure_ap_channel(interface: str) -> int:
    """Return the channel for the AP. Most cards forbid AP mode on 5 GHz
    (NO-IR), so on 5 GHz we first move the connection to 2.4 GHz."""
    freq = get_freq(interface)
    if freq is None:
        sys.exit("Not connected to any Wi-Fi network; cannot determine the channel.")
    if freq < 4000:
        return freq_to_channel(freq)

    profile = saved_profile.get(interface)
    if not profile:
        sys.exit("You are on 5 GHz, which forbids AP mode, and there is no NetworkManager profile to switch bands with.")
    print(f"On 5 GHz channel {freq_to_channel(freq)} (forbids AP mode); switching '{profile}' to 2.4 GHz...")
    saved_band[interface] = nmcli("-g", "802-11-wireless.band", "connection", "show", profile).stdout.strip()
    nmcli("connection", "modify", profile, "802-11-wireless.band", "bg")
    ok = nmcli("connection", "down", profile).returncode == 0
    ok = ok and nmcli("connection", "up", profile, "ifname", interface).returncode == 0
    if not ok:
        restore_band(interface)
        sys.exit(f"Failed to reconnect '{profile}' on 2.4 GHz.")
    for _ in range(15):
        time.sleep(1)
        freq = get_freq(interface)
        if freq is not None and freq < 4000:
            channel = freq_to_channel(freq)
            print(f"Reconnected on 2.4 GHz channel {channel}.")
            return channel
    restore_band(interface)
    sys.exit("Timed out waiting for 2.4 GHz reconnection.")


def create_ap_interface(interface: str) -> str:
    result = run(["iw", "dev", interface, "info"], check=False)
    phy = next((line.split("wiphy")[1].strip() for line in result.stdout.splitlines() if "wiphy" in line), None)
    if phy is None:
        sys.exit(f"Could not determine phy for {interface}.")
    run(["iw", "dev", "uap0", "del"], check=False)  # stale interface from a crashed run
    run(["iw", "phy", f"phy{phy}", "interface", "add", "uap0", "type", "__ap"], check=False)
    if run(["ip", "link", "show", "uap0"], check=False).returncode != 0:
        sys.exit("Failed to create virtual AP interface uap0.")
    nmcli("device", "set", "uap0", "managed", "no")  # NM would flush our static address
    return "uap0"


def setup_network(interface: str, keep_connection: bool) -> None:
    if not keep_connection:
        nmcli("device", "disconnect", interface)
        nmcli("device", "set", interface, "managed", "no")
        run(["ip", "addr", "flush", "dev", interface])
    run(["ip", "addr", "add", f"{GATEWAY}/24", "dev", interface])
    run(["ip", "link", "set", interface, "up"])
    run(["firewall-cmd", "--zone=trusted", "--add-interface", interface], check=False)


def teardown_network(interface: str, keep_connection: bool) -> None:
    run(["firewall-cmd", "--zone=trusted", "--remove-interface", interface], check=False)
    if keep_connection:
        run(["ip", "addr", "del", f"{GATEWAY}/24", "dev", interface], check=False)
        return
    run(["ip", "addr", "flush", "dev", interface], check=False)
    run(["ip", "link", "set", interface, "down"], check=False)
    nmcli("device", "set", interface, "managed", "yes")
    reconnect_wifi(interface)


def write_configs(conf_dir: str, interface: str, ssid: str, channel: int) -> tuple[Path, Path]:
    hostapd_conf = Path(conf_dir) / "hostapd.conf"
    hostapd_conf.write_text(
        f"interface={interface}\n"
        f"driver=nl80211\n"
        f"ssid={ssid}\n"
        f"hw_mode={'a' if channel > 14 else 'g'}\n"
        f"channel={channel}\n"
        f"auth_algs=1\n"
        f"wmm_enabled=0\n"
    )
    dnsmasq_conf = Path(conf_dir) / "dnsmasq.conf"
    dnsmasq_conf.write_text(
        f"interface={interface}\n"
        f"bind-interfaces\n"
        f"listen-address={GATEWAY}\n"
        f"dhcp-range={DHCP_RANGE}\n"
        f"dhcp-option=3,{GATEWAY}\n"
        f"dhcp-option=6,{GATEWAY}\n"
        f"address=/#/{GATEWAY}\n"
        f"dhcp-authoritative\n"
        f"no-resolv\n"
        f"leasefile-ro\n"
        f"dhcp-leasefile={conf_dir}/dnsmasq.leases\n"
    )
    return hostapd_conf, dnsmasq_conf


def start_daemon(cmd: list[str], name: str, conf_dir: str) -> subprocess.Popen:
    log_path = Path(conf_dir) / f"{name}.log"
    with log_path.open("w") as log:
        proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
        time.sleep(2)
    if proc.poll() is not None:
        sys.exit(f"{name} failed to start:\n{log_path.read_text()}")
    return proc


class PortalHandler(BaseHTTPRequestHandler):
    forced_language: str | None = None

    def do_GET(self) -> None:
        if self.path.split("?")[0] == "/":
            lang = pick_language(self.headers.get("Accept-Language", ""), self.forced_language)
            body = render_page(lang).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Language", lang)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(302)
            self.send_header("Location", PORTAL_URL)
            self.send_header("Content-Length", "0")
            self.end_headers()

    do_HEAD = do_GET

    def log_message(self, format: str, *args) -> None:
        print(f"[portal] {self.address_string()} {format % args}")


def start_portal() -> ThreadingHTTPServer:
    server = ThreadingHTTPServer((GATEWAY, 80), PortalHandler)
    server.daemon_threads = True
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(f"Portal serving at {PORTAL_URL}")
    return server


def handle_signal(signum: int, _frame) -> None:
    print(f"\nReceived {signal.Signals(signum).name}, shutting down...")
    shutdown_event.set()


def main() -> None:
    parser = argparse.ArgumentParser(description="Fake Wi-Fi captive portal demo.")
    parser.add_argument("--interface", help="Wireless interface (auto-detected if omitted)")
    parser.add_argument("--ssid", default="Free_Public_WiFi")
    parser.add_argument("--channel", type=int, default=6, help="AP channel in --takeover mode")
    parser.add_argument("--takeover", action="store_true", help="Run the AP on the main interface (disconnects your Wi-Fi)")
    parser.add_argument("--language", choices=sorted(TRANSLATIONS), help="Force portal language (default: follow the client)")
    args = parser.parse_args()

    if os.geteuid() != 0:
        sys.exit("This script must run as root (sudo).")
    missing = [t for t in ("hostapd", "dnsmasq", "iw", "nmcli") if shutil.which(t) is None]
    if missing:
        sys.exit(f"Missing tools: {', '.join(missing)}. Install with: sudo dnf install hostapd dnsmasq")

    interface = args.interface or detect_interface()
    PortalHandler.forced_language = args.language
    saved_profile[interface] = active_profile(interface)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    conf_dir = tempfile.mkdtemp(prefix="fake_wifi_")
    hostapd_proc = dnsmasq_proc = None
    server = None
    ap_iface = None
    hostapd_interface = interface
    try:
        if args.takeover:
            channel = args.channel
        else:
            channel = ensure_ap_channel(interface)
            print(f"Keeping connection on {interface}; AP will use channel {channel}.")
            ap_iface = create_ap_interface(interface)
            hostapd_interface = ap_iface
        print(f"Setting up AP on {hostapd_interface} (SSID: {args.ssid}, channel: {channel})")
        setup_network(hostapd_interface, not args.takeover)
        hostapd_conf, dnsmasq_conf = write_configs(conf_dir, hostapd_interface, args.ssid, channel)
        hostapd_proc = start_daemon(["hostapd", str(hostapd_conf)], "hostapd", conf_dir)
        # hostapd may bounce the interface; make sure the gateway address survived
        if GATEWAY not in run(["ip", "addr", "show", "dev", hostapd_interface], check=False).stdout:
            run(["ip", "addr", "add", f"{GATEWAY}/24", "dev", hostapd_interface])
        dnsmasq_proc = start_daemon(["dnsmasq", "--no-daemon", f"--conf-file={dnsmasq_conf}"], "dnsmasq", conf_dir)
        server = start_portal()
        print(f"AP is up. Connect to '{args.ssid}', then press Ctrl+C to shut down.")
        shutdown_event.wait()
    finally:
        print("Cleaning up...")
        if server:
            server.shutdown()
        for proc in (hostapd_proc, dnsmasq_proc):
            if proc and proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
        teardown_network(hostapd_interface, not args.takeover)
        if ap_iface:
            run(["iw", "dev", ap_iface, "del"], check=False)
        restore_band(interface)
        shutil.rmtree(conf_dir, ignore_errors=True)
        print("Done. Network state restored.")


if __name__ == "__main__":
    main()
