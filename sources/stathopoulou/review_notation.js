// ---- notation: the validator's renderStaff/renderTubs plus tuplets and τρίλια ----
function getVF(){ return (window.Vex && (window.Vex.Flow || window.Vex)) || null; }
function greekGlyph(c){ if(!c) return ""; const g=c.glyph; let t = g==="dum"?">":g==="tek"?"Δ":g==="ka"?"Α":g==="slap"?"S":""; return t; }
function tubsCell(c, cls){
  const d=document.createElement('div'); d.className=cls;
  if(c && c.span && c.span!==1) d.style.setProperty('--w', (30*c.span)+'px');
  const t=greekGlyph(c);
  if(c&&c.middle){ const s=document.createElement('span'); s.className='circled'; s.textContent=t; d.appendChild(s); }
  else d.textContent=t;
  if(c&&c.trill){ const s=document.createElement('span'); s.className='trill'; s.textContent='~'; d.appendChild(s); }
  return d;
}
function renderTubs(bar,bpb){
  const wrap=document.createElement('div'); wrap.className='bar';
  if(bar.repeat){ const r=document.createElement('div'); r.className='repeat-cell'; const p=document.createElement('div'); p.className='pct'; r.appendChild(p); wrap.appendChild(r); return wrap; }
  const n=bar.cells.length;
  const row=document.createElement('div'); row.className='row greek';
  let pos=0;
  bar.cells.forEach((c,i)=>{
    const span=(c&&c.span)||1;
    const onBeat=Math.abs(pos-Math.round(pos))<1e-6 && Math.round(pos)%bpb===0;
    let cl='cell'+(i===0?' first':onBeat?' beat':(span!==1?' tup':' sub'))+(i===n-1?' barend':'');
    row.appendChild(tubsCell(c,cl)); pos+=span;
  });
  wrap.appendChild(row);
  const cr=document.createElement('div'); cr.className='row count';
  pos=0;
  bar.counts.forEach(([lab,span],i)=>{
    const onBeat=Math.abs(pos-Math.round(pos))<1e-6 && Math.round(pos)%bpb===0;
    const d=document.createElement('div'); d.className='cell'+(i===0?' first':onBeat?' beat':' sub');
    if(span!==1) d.style.setProperty('--w',(30*span)+'px');
    d.textContent=lab; cr.appendChild(d); pos+=span;
  });
  wrap.appendChild(cr);
  return wrap;
}
const DURMAP={1:'w',2:'h',4:'q',8:'8',16:'16',32:'32',64:'64'};
const KEY={dum:'b/4',tek:'d/5',ka:'f/5',slap:'e/5'}, REST_KEY='d/5';
function vfDur(durStr){ const dot=durStr.endsWith('.'); const base=parseInt(dot?durStr.slice(0,-1):durStr,10); return {d:DURMAP[base]||'q',dot}; }
function renderStaff(container,bars,beats,maxWidth){
  let els=[];
  try{
    const VF=getVF(); if(!VF) throw new Error('VexFlow not loaded');
    const flat=[]; bars.forEach(b=>{ if(b.repeat){flat.push({repeat:true});} else b.events.forEach(e=>flat.push(e)); });
    let width=Math.max(360, flat.length*46+90);
    if(maxWidth && maxWidth>240 && maxWidth<width) width=Math.max(240, Math.floor(maxWidth));   // fit the phone: VexFlow squeezes the bar into the column
    const div=document.createElement('div'); container.appendChild(div);
    const renderer=new VF.Renderer(div,VF.Renderer.Backends.SVG);
    renderer.resize(width,150); const ctx=renderer.getContext();
    const stave=new VF.Stave(4,18,width-10); stave.setNumLines(3); stave.setContext(ctx).draw();
    const notes=[], beamGroups=[], tupGroups={}; let cur=[];
    flat.forEach(e=>{
      if(e.repeat){ notes.push(new VF.TextNote({text:'％',duration:'q'}).setLine(2).setJustification(VF.TextNote.Justification.CENTER)); return; }
      const {d,dot}=vfDur(e.dur); let n;
      if(e.drum===null){ n=new VF.StaveNote({keys:[REST_KEY],duration:d+'r'}); }
      else {
        n=new VF.StaveNote({keys:[KEY[e.drum]||'c/5'],duration:d});
        const lab = e.label || (e.drum==='ka'&&e.middle ? 'Ⓐ' : ({dum:'>',tek:'Δ',ka:'Α',slap:'S'})[e.drum]);
        n.addModifier(new VF.Annotation(lab).setVerticalJustification(VF.Annotation.VerticalJustify.BOTTOM),0);
        if(e.accent) n.addModifier(new VF.Articulation('a>').setPosition(3),0);
        if(e.trill){ try{ n.addModifier(new VF.Tremolo(3),0); }catch(_){ } }   // roll: tremolo slashes on the stem
        if(e.grace && e.grace.length){                                           // lead-in roll: beamed, slashed grace notes before the note
          try{
            const gn=e.grace.map(g=>new VF.GraceNote({keys:[KEY[g.drum]||'f/5'],duration:DURMAP[g.dur]||'32',slash:false}));   // no acciaccatura slash: on a beamed group it drew a 'roof' over the beams (Nikos, 15 Oct 2026)
            const grp=new VF.GraceNoteGroup(gn,true); grp.beamNotes(); n.addModifier(grp,0);
          }catch(_){ }
        }
      }
      if(dot){ try{VF.Dot.buildAndAttach([n],{all:true});}catch(_){ } }
      notes.push(n);
      if(e.group){ (tupGroups[e.group]=tupGroups[e.group]||{notes:[],ratio:e.tuplet}).notes.push(n); }
      if(e.drum!==null){
        if(e.beam==='[') cur=[n]; else if(e.beam===']'){ cur.push(n); if(cur.length>1)beamGroups.push(cur); cur=[]; } else if(cur.length) cur.push(n);
      }
    });
    const voice=new VF.Voice({num_beats:beats||4,beat_value:4}).setStrict(false); voice.addTickables(notes);
    const beams=beamGroups.map(g=>{ try{ const b=new VF.Beam(g); b.render_options.flat_beams=true; return b; }catch(_){ return null; } }).filter(Boolean);
    const tuplets=Object.values(tupGroups).map(g=>{ try{ return new VF.Tuplet(g.notes,{num_notes:g.ratio[0],notes_occupied:g.ratio[1],bracketed:true,location:1}); }catch(_){ return null; } }).filter(Boolean);
    new VF.Formatter().joinVoices([voice]).format([voice],width-40);
    voice.draw(ctx,stave);
    beams.forEach(b=>{ try{ b.setContext(ctx).draw(); }catch(_){ } });
    tuplets.forEach(t=>{ try{ t.setContext(ctx).draw(); }catch(_){ } });
    try{ els=notes.map(n=>{ try{
      if(n.getSVGElement){ const g=n.getSVGElement(); if(g) return g; }
      const id=n.getAttribute&&n.getAttribute('id'); if(!id) return null;
      return div.querySelector('#vf-'+CSS.escape(String(id)))||document.getElementById('vf-'+id)||document.getElementById(String(id))||null;
    }catch(_){ return null; } }); }catch(_){ }
    try{ container.querySelectorAll('text').forEach(t=>{ if(t.textContent==='>'){ const y=parseFloat(t.getAttribute('y')||'0'); t.setAttribute('y',String(y+3)); t.setAttribute('font-size','17'); t.setAttribute('font-weight','600'); } }); }catch(_){ }   // the > sits on the letters' optical centre
  }catch(err){ const f=document.createElement('div'); f.className='fallback'; f.textContent='staff render skipped: '+err; container.appendChild(f); }
  return els;
}
function renderNotation(container, v, opts){
  opts=opts||{};
  const vd=document.createElement('div'); vd.className='notation';
  const vhead=document.createElement('div'); vhead.className='vhead';
  const lbl=document.createElement('span'); lbl.className='vlabel'; lbl.textContent=v.id+' | '+v.meter+' | bpb '+v.bpb; vhead.appendChild(lbl);
  const code=document.createElement('span'); code.className='vcode'; code.textContent=v.rhythm; vhead.appendChild(code);
  vd.appendChild(vhead);
  const st=document.createElement('div'); st.className='staff'; const els=renderStaff(st, v.bars, v.beats, opts.width); vd.appendChild(st);
  let k=0; v.bars.forEach(b=>{ if(b.repeat){ b._els=[]; k++; } else { b._els=b.events.map(()=>els[k++]||null); } });   // one SVG group per event, for highlighting
  if(opts.tubs!==false && v.bars.every(b=>b.repeat||b.cells)){
    const tb=document.createElement('div'); tb.className='tubs';
    v.bars.forEach((b,i)=>{ const el=renderTubs(b,v.bpb); if(i) el.style.marginLeft='10px'; tb.appendChild(el); });
    vd.appendChild(tb);
    const lg=document.createElement('div'); lg.className='legend';
    lg.textContent='Greek TUBS row and count row. Thick line = bar end, medium = beat, dashed = sub-beat, dotted = tuplet cell. Circled = middle-finger kah. ~ = τρίλια (tremolo slashes on the staff).';
    vd.appendChild(lg);
  }
  if(opts.legend){ const lg=document.createElement('div'); lg.className='legend'; lg.textContent=opts.legend; vd.appendChild(lg); }
  container.appendChild(vd);
}
