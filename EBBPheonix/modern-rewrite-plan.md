# EBB Phoenix modern rewrite plan

## Goal
Create a smaller, cleaner, more maintainable modern rewrite of the original ElkBuffBars idea for Anniversary TBC / modern Classic-era client compatibility.

## Core principles
- Keep the addon small and explicit.
- Put version compatibility in one place.
- Use a real data model before rendering.
- Avoid global API assumptions.
- Prefer modern C_ API usage when available, with legacy fallbacks.
- Separate data collection, state management, layout, and rendering.

## Architecture

### 1. Compatibility layer
Keep all client-version checks and API wrappers in a single module.
Responsibilities:
- detect retail / classic / TBC branch
- wrap `C_UnitAuras` and `UnitAura`
- wrap debuff/class color lookups
- expose safe accessors for tracker and frame APIs

### 2. Data layer
Build normalized aura records before any UI code runs.
Each aura record contains:
- name
- icon
- type
- unit
- source
- expiration
- remaining
- debuffType
- charges
- spellId

### 3. Layout / configuration layer
Define groups and layouts as data objects.
Each group contains:
- id
- name
- unit
- filter
- width
- height
- anchor point
- direction
- icon mode
- text mode
- bars visibility options

### 4. Renderer layer
A renderer should consume aura records and render bars into frames.
It should not own aura scanning logic.
It should not contain client-version branching logic beyond color/material helpers.

### 5. Update cycle
The addon should use a single refresh cycle.
- collect aura data
- normalize it
- patch dirty groups
- render visible groups only

### 6. Event model
Use the WoW event system with a central event dispatcher.
Only refresh affected units and groups.
Avoid giant monolithic update functions.

## File structure
- Core.lua - addon bootstrap and event manager
- Compat.lua - compatibility layer
- AuraData.lua - aura normalization and scanning
- Layout.lua - group and layout definitions
- Renderer.lua - bar rendering and UI creation
- Main.lua - orchestrates refresh and events
- EBBPhoenix.toc - addon registration

## Expected benefits
- easier debugging
- less project-version drift
- smaller code surface in one feature area
- easier future maintenance for Anniversary/TBC and modern Classic APIs

## Implementation target
This rewrite is intentionally small, modern, and focused. It is not a clone of the full old codebase. It keeps the original purpose — a compact, fast buff/debuff bar system — while reworking the design around modularity and compatibility.
