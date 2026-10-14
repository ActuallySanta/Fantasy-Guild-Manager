"""Writes the hand-drawn style SVG icons used by the Mobile Ledger UI."""
import os
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Art", "Icons")
os.makedirs(OUT, exist_ok=True)
INK = "#3A2816"
S = f'stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round"'
ICONS = {
 "sun": f'''<g {S}><path d="M48 6v12M48 78v12M6 48h12M78 48h12M18 18l9 9M69 69l9 9M18 78l9-9M69 27l9-9" fill="none"/>
  <circle cx="48" cy="48" r="20" fill="#F2C14E"/></g><path d="M38 44q4-4 8 0M50 44q4-4 8 0M40 56q8 6 16 0" fill="none" stroke="{INK}" stroke-width="3.5" stroke-linecap="round"/>''',
 "coins": f'''<g {S}><path d="M12 56v14c0 5 10 9 22 9s22-4 22-9V56" fill="#D9A93F"/><ellipse cx="34" cy="56" rx="22" ry="9" fill="#F2C962"/>
  <path d="M40 34v16c0 5 10 9 22 9s22-4 22-9V34" fill="#D9A93F"/><ellipse cx="62" cy="34" rx="22" ry="9" fill="#F2C962"/>
  <path d="M40 72v6c0 5 10 9 22 9s22-4 22-9v-6" fill="#D9A93F"/><path d="M40 62v10c0 5 10 9 22 9s22-4 22-9V62" fill="#D9A93F"/><ellipse cx="62" cy="62" rx="22" ry="9" fill="#F2C962"/></g>''',
 "rook": f'''<g {S}><path d="M26 84h44l-4-10H30z" fill="#B9A588"/><path d="M32 74l4-36h24l4 36z" fill="#D8C7A8"/>
  <path d="M24 14h10v8h8v-8h12v8h8v-8h10v18l-8 8H32l-8-8z" fill="#D8C7A8"/></g><path d="M44 56h8v14h-8z" fill="{INK}"/>''',
 "strength": f'''<g {S}><path d="M18 82C10 62 16 44 30 36l6-16c3-8 16-9 20-2l4 8c3 6-3 11-9 9l-4-2-2 10c10-6 28-4 34 9 7 14-2 30-20 31z" fill="#E8B48A"/>
  <path d="M46 52c6-2 14 0 16 6" fill="none"/></g>''',
 "defense": f'''<g {S}><path d="M48 8l34 12v24c0 22-15 36-34 44C29 80 14 66 14 44V20z" fill="#4F86C6"/>
  <path d="M48 18l24 9v17c0 16-10 26-24 32C34 70 24 60 24 44V27z" fill="#D9B45A"/><path d="M48 18v58" fill="none"/></g>''',
 "wisdom": f'''<g {S}><path d="M8 24c14-6 28-6 40 4v56c-12-10-26-10-40-4z" fill="#F4E6C4"/><path d="M88 24c-14-6-28-6-40 4v56c12-10 26-10 40-4z" fill="#EAD7AE"/>
  <path d="M8 24v56M88 24v56" fill="none"/></g><path d="M16 38c8-3 16-3 24 2M16 50c8-3 16-3 24 2M56 40c8-5 16-5 24-2M56 52c8-5 16-5 24-2" fill="none" stroke="#8B6A3E" stroke-width="3" stroke-linecap="round"/>''',
 "sleaziness": f'''<g {S}><path d="M6 36c14-6 28-6 42 2 14-8 28-8 42-2 0 20-10 32-24 32-9 0-12-8-18-8s-9 8-18 8C16 68 6 56 6 36z" fill="#5E8F4A"/></g>
  <path d="M20 44c6-4 12-4 16 2-6 4-12 4-16-2zM60 46c4-6 10-6 16-2-4 6-10 6-16 2z" fill="{INK}"/>''',
 "pluck": f'''<g {S}><path d="M48 6c4 16 30 24 30 50a30 30 0 0 1-60 0c0-12 8-18 10-28 8 4 12 12 14 18 6-10 8-24 6-40z" fill="#EB8A3A"/>
  <path d="M48 52c2 8 14 10 14 22a14 14 0 0 1-28 0c0-6 4-8 6-14 4 2 6 6 6 8 2-4 3-10 2-16z" fill="#F7D35C"/></g>''',
 "injury": f'''<g {S}><path d="M48 84S10 62 10 34a19 19 0 0 1 38-6 19 19 0 0 1 38 6c0 28-38 50-38 50z" fill="#E07A6E"/>
  <path d="M30 38l36 22M66 38L30 60" fill="none" stroke="#FFF6E4" stroke-width="7"/></g>''',
 "heart": f'''<g {S}><path d="M48 84S10 62 10 34a19 19 0 0 1 38-6 19 19 0 0 1 38 6c0 28-38 50-38 50z" fill="#6FB15A"/></g>''',
 "check": f'''<path d="M16 50l20 20 44-44" fill="none" stroke="#FFFFFF" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>''',
 "x": f'''<path d="M22 22l52 52M74 22L22 74" fill="none" stroke="#FFFFFF" stroke-width="12" stroke-linecap="round"/>''',
 "plus": f'''<path d="M48 16v64M16 48h64" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round"/>''',
 "back": f'''<path d="M82 48H16M40 22L14 48l26 26" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>''',
 "chev_down": f'''<path d="M18 34l30 30 30-30" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>''',
 "chev_up": f'''<path d="M18 62l30-30 30 30" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>''',
 "chev_right": f'''<path d="M36 18l30 30-30 30" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>''',
 "emblem": f'''<g {S}><path d="M14 14l8-2 52 52-6 6z" fill="#D9DDE2"/><path d="M82 14l-8-2-52 52 6 6z" fill="#D9DDE2"/>
  <path d="M10 70l14 14M86 70L72 84" fill="none" stroke-width="7"/><path d="M48 30l22 8v14c0 14-10 22-22 28-12-6-22-14-22-28V38z" fill="#C9A24E"/>
  <path d="M48 38l14 5v9c0 9-6 14-14 18-8-4-14-9-14-18v-9z" fill="#E6C771"/></g>''',
 "office": f'''<g {S}><path d="M84 8C58 12 38 30 30 58c22-4 48-18 54-50z" fill="#F4E6C4"/><path d="M60 30L30 58l-14 28" fill="none"/></g>''',
 "training": f'''<g {S}><circle cx="48" cy="48" r="38" fill="#F4E6C4"/><circle cx="48" cy="48" r="24" fill="#E07A6E"/><circle cx="48" cy="48" r="10" fill="#F4E6C4"/></g>''',
 "hospital": f'''<g {S}><path d="M36 10h24v26h26v24H60v26H36V60H10V36h26z" fill="#FFF6E4"/></g><path d="M42 16h12v26h26v12H54v26H42V54H16V42h26z" fill="#C9423E"/>''',
 "armory": f'''<g {S}><path d="M18 40h56c0 10-8 16-18 16H40v10h12v14H24V66h12V56c-10-2-18-8-18-16z" fill="#8A929C"/><path d="M74 40l14-6v12z" fill="#8A929C"/>
  <path d="M60 10l18 18-8 8-18-18z" fill="#B07A3E"/></g>''',
 "barracks": f'''<g {S}><path d="M8 62h80v14H8z" fill="#B07A3E"/><path d="M8 82V24M88 82V48" fill="none"/><path d="M40 62V46h40c5 0 8 3 8 8v8z" fill="#C9423E"/>
  <circle cx="24" cy="50" r="10" fill="#F4E6C4"/></g>''',
 "nav_characters": f'''<g {S}><circle cx="48" cy="30" r="17" fill="{INK}"/><path d="M14 88c0-20 15-34 34-34s34 14 34 34z" fill="{INK}"/></g>''',
 "nav_quests": f'''<g {S}><path d="M22 10h50v76H22z" fill="#F4E6C4"/><path d="M14 10h66a8 8 0 0 1 0 16H14a8 8 0 0 1 0-16z" fill="#E2CB98"/></g>
  <path d="M32 40h32M32 52h32M32 64h20" stroke="{INK}" stroke-width="5" stroke-linecap="round"/><circle cx="66" cy="76" r="11" fill="#B32B2E" stroke="{INK}" stroke-width="4"/>''',
 "nav_home": f'''<g {S}><path d="M18 46v40h60V46" fill="{INK}"/><path d="M8 50L48 14l40 36" fill="none" stroke-width="9"/></g><path d="M41 86V64h14v22z" fill="#E2CB98"/>''',
 "nav_upgrades": f'''<path d="M48 84V20M22 44l26-26 26 26" fill="none" stroke="{INK}" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>''',
 "nav_settings": f'''<g fill="{INK}"><circle cx="48" cy="48" r="28"/>{"".join(f'<rect x="41" y="4" width="14" height="22" rx="4" transform="rotate({a} 48 48)"/>' for a in range(0,360,45))}</g><circle cx="48" cy="48" r="11" fill="#E2CB98"/>''',
}
for name, body in ICONS.items():
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96" color="#FFFFFF">{body}</svg>'
    open(os.path.join(OUT, name + ".svg"), "w").write(svg)
print(len(ICONS), "icons")
