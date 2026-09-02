#!/usr/bin/env python3
"""Pareto front of LLM conservative score vs. price, from llm-stats.com data.

Fetches live from the site's backend (api.zeroeval.com):
  - /leaderboard/indexes/compact  -> conservative scores per category
  - /leaderboard/models/full      -> input/output prices

Shows the result in a separate desktop window (matplotlib): price (log scale)
vs. conservative score, points coloured by organization, model names on hover,
pareto front highlighted.
"""

from __future__ import annotations

import json
import sys
import urllib.request
from dataclasses import dataclass
from typing import Any

BACKEND = "https://api.zeroeval.com"
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

# Output tokens dominate most workloads; blend = (input + blend * output) / (1 + blend).
BLEND = 3.0


@dataclass(frozen=True)
class Model:
    model_id: str
    name: str
    organization: str
    conservative: float
    input_price: float
    output_price: float

    def blended_price(self) -> float:
        return (self.input_price + BLEND * self.output_price) / (1.0 + BLEND)


def http_get_json(url: str) -> Any:
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def load_models() -> list[Model]:
    indexes = http_get_json(f"{BACKEND}/leaderboard/indexes/compact")["general"]["models"]
    priced = {m["model_id"]: m for m in http_get_json(f"{BACKEND}/leaderboard/models/full?justCanonicals=false")}

    models: list[Model] = []
    for entry in indexes:
        price = priced.get(entry["model_id"])
        if not price or price.get("input_price") is None or price.get("output_price") is None:
            continue  # no public pricing -> cannot be placed on a price axis
        models.append(
            Model(
                model_id=entry["model_id"],
                name=entry.get("model_name") or price.get("name") or entry["model_id"],
                organization=entry.get("organization_name") or price.get("organization") or "",
                conservative=entry["conservative"],
                input_price=price["input_price"],
                output_price=price["output_price"],
            )
        )
    if not models:
        sys.exit("No models with both a score and pricing found.")
    return models


def pareto_front(models: list[Model]) -> list[Model]:
    """Front of (max conservative, min price): sort by price asc, keep score records."""
    ordered = sorted(models, key=lambda m: (m.blended_price(), -m.conservative))
    front: list[Model] = []
    best = float("-inf")
    for model in ordered:
        if model.conservative > best:
            front.append(model)
            best = model.conservative
    return front


def org_color(organization: str) -> str:
    """Deterministic colour derived from the organization name itself."""
    import colorsys

    digest = sum(ord(c) * (i + 1) for i, c in enumerate(organization))
    hue = (digest * 137.508) % 360  # golden-angle spread keeps neighbours apart
    r, g, b = colorsys.hls_to_rgb(hue / 360, 0.55, 0.65)
    return f"#{int(r * 255):02x}{int(g * 255):02x}{int(b * 255):02x}"


def show_plot(models: list[Model], front: list[Model]) -> None:
    import matplotlib.pyplot as plt
    from matplotlib.ticker import FixedLocator, NullFormatter, NullLocator, ScalarFormatter

    fig, ax = plt.subplots(figsize=(12, 7))
    orgs = sorted({m.organization for m in models})
    scatters: dict[str, plt.PathCollection] = {}
    for org in orgs:
        members = [m for m in models if m.organization == org]
        scatters[org] = ax.scatter(
            [m.blended_price() for m in members],
            [m.conservative for m in members],
            s=30,
            alpha=0.75,
            color=org_color(org),
            label=org,
        )
    ax.step(
        [m.blended_price() for m in front],
        [m.conservative for m in front],
        where="post",
        color="crimson",
        lw=1.5,
        ls="--",
        label="pareto front",
        zorder=3,
    )
    ax.set_xscale("log")
    # Plain-number ticks (0.1, 0.2, 0.5, 1, ...) instead of powers of ten.
    ax.xaxis.set_major_locator(FixedLocator([0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100]))
    ax.xaxis.set_major_formatter(ScalarFormatter())
    ax.xaxis.set_minor_locator(NullLocator())
    ax.xaxis.set_minor_formatter(NullFormatter())
    ax.set_xlabel("price, $ per million tokens (25% input / 75% output)")
    ax.set_ylabel("conservative score")
    ax.set_title("LLM score vs. price")
    ax.grid(alpha=0.25)
    leg = ax.legend(fontsize=7, loc="upper left", bbox_to_anchor=(1.01, 1))
    fig.subplots_adjust(right=0.75)

    # Hover tooltip: the nearest point within 15 px shows its details.
    xs = [m.blended_price() for m in models]
    ys = [m.conservative for m in models]
    labels = [
        f"{m.name}\n{m.organization}\n"
        f"{m.input_price:.3f} in / {m.output_price:.3f} out $/M\nscore {m.conservative:.2f}"
        for m in models
    ]
    annot = ax.annotate(
        "",
        xy=(0, 0),
        xytext=(12, 12),
        textcoords="offset points",
        bbox=dict(boxstyle="round", fc="#ffffe0", ec="0.5", alpha=0.9),
        arrowprops=dict(arrowstyle="->"),
        annotation_clip=False,
        zorder=10,  # keep the tooltip above points, grid and legend
    )
    annot.set_visible(False)

    # Hovering a legend entry fades every other creator's points. Hit testing
    # uses the legend's row bands (marker + text) because scatter legend handles
    # are PathCollections, not lines with pickradius.
    leg_rows = [
        (text, org) for text, org in zip(leg.get_texts(), orgs)
    ]

    def set_dim(hovered: str | None) -> None:
        for org, sc in scatters.items():
            sc.set_alpha(0.75 if hovered is None or org == hovered else 0.12)

    def on_move(event) -> None:
        if event.x is not None:
            hovered = None
            for text, org in leg_rows:
                bb = text.get_window_extent()
                band = bb.expanded(1.0, 1.4)
                band.x0 = leg.get_window_extent(fig.canvas.get_renderer()).x0  # include the marker
                if band.contains(event.x, event.y):
                    hovered = org
                    break
            if hovered is not None:
                set_dim(hovered)
                if annot.get_visible():
                    annot.set_visible(False)
                fig.canvas.draw_idle()
                return
        if any(sc.get_alpha() != 0.75 for sc in scatters.values()):
            set_dim(None)

        if event.inaxes is not ax or event.x is None:
            if annot.get_visible():
                annot.set_visible(False)
                fig.canvas.draw_idle()
            return
        pts = ax.transData.transform(list(zip(xs, ys)))
        d2 = (pts[:, 0] - event.x) ** 2 + (pts[:, 1] - event.y) ** 2
        i = int(d2.argmin())
        if d2[i] < 15**2:
            annot.xy = (xs[i], ys[i])
            annot.set_text(labels[i])
            annot.set_visible(True)
            fig.canvas.draw_idle()
        elif annot.get_visible():
            annot.set_visible(False)
            fig.canvas.draw_idle()

    fig.canvas.mpl_connect("motion_notify_event", on_move)
    plt.show()


def main() -> None:
    models = load_models()
    front = pareto_front(models)
    show_plot(models, front)


if __name__ == "__main__":
    main()
