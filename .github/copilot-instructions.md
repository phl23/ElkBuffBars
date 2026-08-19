# World of Warcraft API Reference

For World of Warcraft addon API research, consult https://warcraft.wiki.gg/wiki/World_of_Warcraft_API before choosing an implementation. Check that a function is available for every supported client version listed in `Phoenix/Phoenix.toc`; do not assume a Retail-only API is available in Classic.

# Phoenix Release Policy

When preparing a Phoenix commit, increment the version in `Phoenix/Core.lua` and `Phoenix/Phoenix.toc`, and add an entry to `Phoenix/CHANGES.txt`. Do not increment the version for interim edits.