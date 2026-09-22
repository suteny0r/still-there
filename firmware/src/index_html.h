#pragma once

static const char INDEX_HTML[] = R"HTML(<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Turret</title>
<style>
:root{color-scheme:dark}
body{margin:0;background:#111;color:#ddd;font:14px system-ui,sans-serif}
.wrap{display:flex;flex-wrap:wrap;gap:16px;padding:12px;max-width:1100px;margin:auto}
.view{flex:1 1 360px;min-width:300px}
.panel{flex:1 1 300px;min-width:280px}
#img{width:100%;max-width:480px;aspect-ratio:1;background:#000;display:block;border:1px solid #333;cursor:crosshair;image-rendering:auto}
.row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin:6px 0}
button{background:#2a2a2a;color:#eee;border:1px solid #444;border-radius:4px;padding:6px 10px;cursor:pointer}
button.on{background:#2d6a2d;border-color:#4c4}
button.fire{background:#5a1a1a;border-color:#a33}
button.fire.on{background:#c22;border-color:#f66}
label{display:flex;justify-content:space-between;gap:8px;align-items:center;margin:4px 0}
label span.v{min-width:44px;text-align:right;color:#9cf}
input[type=range]{flex:1;margin:0 8px}
.stat{font-family:ui-monospace,monospace;font-size:12px;color:#aaa;white-space:pre-wrap;background:#181818;padding:8px;border-radius:4px;border:1px solid #2a2a2a}
h3{margin:12px 0 4px;font-size:13px;color:#888;text-transform:uppercase;letter-spacing:.06em}
.lock{color:#f55;font-weight:bold}
.pad{display:grid;grid-template-columns:repeat(3,44px);gap:4px}
.pad button{height:36px}
</style></head><body>
<div class="wrap">
 <div class="view">
  <img id="img" alt="stream">
  <div class="row">
   <button data-mode="0" class="m">Manual</button>
   <button data-mode="1" class="m" id="mface">Person</button>
   <button data-mode="2" class="m">Motion</button>
   <button data-mode="3" class="m">Scan</button>
   <button id="laser" class="fire">Laser</button>
   <button id="autofire">Auto-fire</button>
  </div>
  <div class="row">
   <div class="pad">
    <span></span><button data-n="0,5">&#9650;</button><span></span>
    <button data-n="-5,0">&#9664;</button><button id="center">&#9679;</button><button data-n="5,0">&#9654;</button>
    <span></span><button data-n="0,-5">&#9660;</button><span></span>
   </div>
   <div class="stat" id="stat" style="flex:1">connecting...</div>
  </div>
  <div class="stat">Click the image to aim. Arrow keys nudge, Space centers, L toggles laser, 1-4 select mode.</div>
 </div>
 <div class="panel">
  <h3>Servo</h3>
  <label>Pan <input type="range" id="pan" min="0" max="180" step="1"><span class="v" id="panv"></span></label>
  <label>Tilt <input type="range" id="tilt" min="35" max="145" step="1"><span class="v" id="tiltv"></span></label>
  <label>Pan trim <input type="range" data-var="pantrim" min="-30" max="30" step="0.5" data-key="panTrim"><span class="v"></span></label>
  <label>Tilt trim <input type="range" data-var="tilttrim" min="-30" max="30" step="0.5" data-key="tiltTrim"><span class="v"></span></label>
  <div class="row"><button data-t="invpan" data-key="invPan">Invert pan</button><button data-t="invtilt" data-key="invTilt">Invert tilt</button></div>
  <h3>Tracking</h3>
  <label>Gain kp <input type="range" data-var="kp" min="1" max="60" step="0.5" data-key="kp"><span class="v"></span></label>
  <label>Smoothing <input type="range" data-var="smooth" min="0.05" max="1" step="0.05" data-key="smooth"><span class="v"></span></label>
  <label>Max step &deg;/tick <input type="range" data-var="maxstep" min="0.2" max="10" step="0.2" data-key="maxStep"><span class="v"></span></label>
  <label>Deadband px <input type="range" data-var="dead" min="0" max="60" step="1" data-key="dead"><span class="v"></span></label>
  <label>Settle ms <input type="range" data-var="settle" min="0" max="1500" step="50" data-key="settle"><span class="v"></span></label>
  <label>Lost ms <input type="range" data-var="lost" min="200" max="10000" step="100" data-key="lost"><span class="v"></span></label>
  <label>Lock ms <input type="range" data-var="lockms" min="0" max="3000" step="100" data-key="lockMs"><span class="v"></span></label>
  <label>Lock release x deadband <input type="range" data-var="lockrel" min="1" max="8" step="0.5" data-key="lockRelease"><span class="v"></span></label>
  <label>Aim below face (face widths) <input type="range" data-var="aimbelow" min="-1" max="4" step="0.1" data-key="aimBelow"><span class="v"></span></label>
  <div class="row"><button data-t="torso" data-key="torso">Torso color tracking</button></div>
  <label>Face re-detect ms <input type="range" data-var="redetect" min="200" max="5000" step="100" data-key="redetect"><span class="v"></span></label>
  <label>Torso min confidence <input type="range" data-var="torsoconf" min="0.02" max="0.6" step="0.01" data-key="torsoConf"><span class="v"></span></label>
  <label>Drop track w/o face (s) <input type="range" data-var="facetmo" min="1000" max="30000" step="1000" data-key="faceTimeout"><span class="v"></span></label>
  <label>Aim down body (fraction) <input type="range" data-var="aimfrac" min="0" max="1" step="0.05" data-key="aimFrac"><span class="v"></span></label>
  <label>Person score threshold <input type="range" data-var="personthr" min="0.1" max="0.95" step="0.05" data-key="personThr"><span class="v"></span></label>
  <div class="row"><button data-t="scan" data-key="scan">Scan when lost</button></div>
  <label>Scan speed &deg;/s <input type="range" data-var="scanspeed" min="2" max="120" step="1" data-key="scanSpeed"><span class="v"></span></label>
  <label>Scan tilt <input type="range" data-var="scantilt" min="35" max="145" step="1" data-key="scanTilt"><span class="v"></span></label>
  <label>Tracking tilt max <input type="range" data-var="ttmax" min="35" max="145" step="1" data-key="trackTiltMax"><span class="v"></span></label>
  <h3>Motion detector</h3>
  <label>Threshold <input type="range" data-var="mthr" min="2" max="100" step="1" data-key="mthr"><span class="v"></span></label>
  <label>Min cells <input type="range" data-var="mmin" min="1" max="60" step="1" data-key="mmin"><span class="v"></span></label>
  <h3>Camera</h3>
  <label>JPEG quality <input type="range" data-var="quality" min="10" max="95" step="5" data-key="quality"><span class="v"></span></label>
  <div class="row"><button data-t="hmirror" data-key="hmirror">H-mirror</button><button data-t="vflip" data-key="vflip">V-flip</button></div>
  <div class="row"><button id="save">Save settings</button><button id="defaults">Defaults</button><a href="/capture" target="_blank"><button>Capture</button></a></div>
  <div class="stat">Save also stores the current mode as the power-up mode (default: Person).</div>
 </div>
</div>
<script>
const $=s=>document.querySelector(s), $$=s=>[...document.querySelectorAll(s)];
const host=location.hostname;
$('#img').src='http://'+host+':81/stream';
let st={}, editing=null, faceOk=true;
function ctl(v,val){return fetch('/control?var='+v+'&val='+encodeURIComponent(val)).catch(()=>{});}
$$('.m').forEach(b=>b.onclick=()=>ctl('mode',b.dataset.mode));
$$('[data-n]').forEach(b=>b.onclick=()=>{const [p,t]=b.dataset.n.split(',');if(+p)ctl('npan',p);if(+t)ctl('ntilt',t);});
$('#center').onclick=()=>ctl('center',1);
$('#laser').onclick=()=>ctl('laser',st.laser?0:1);
$('#autofire').onclick=()=>ctl('autofire',st.autoFire?0:1);
$('#save').onclick=()=>ctl('save',1);
$('#defaults').onclick=()=>ctl('defaults',1);
$$('[data-t]').forEach(b=>b.onclick=()=>ctl(b.dataset.t,st[b.dataset.key]?0:1));
$$('input[data-var]').forEach(r=>{
  r.oninput=()=>{r.nextElementSibling.textContent=r.value;editing=r;};
  r.onchange=()=>{ctl(r.dataset.var,r.value);editing=null;};
});
const pan=$('#pan'),tilt=$('#tilt');
pan.oninput=()=>{$('#panv').textContent=pan.value;editing=pan;}; pan.onchange=()=>{ctl('pan',pan.value);editing=null;};
tilt.oninput=()=>{$('#tiltv').textContent=tilt.value;editing=tilt;}; tilt.onchange=()=>{ctl('tilt',tilt.value);editing=null;};
$('#img').onclick=e=>{const r=e.target.getBoundingClientRect();const x=Math.round((e.clientX-r.left)/r.width*240),y=Math.round((e.clientY-r.top)/r.height*240);fetch('/aim?x='+x+'&y='+y).catch(()=>{});};
document.onkeydown=e=>{
  if(e.target.tagName==='INPUT')return;
  const k=e.key;
  if(k==='ArrowLeft')ctl('npan',-3);else if(k==='ArrowRight')ctl('npan',3);
  else if(k==='ArrowUp')ctl('ntilt',3);else if(k==='ArrowDown')ctl('ntilt',-3);
  else if(k===' ')ctl('center',1);else if(k==='l'||k==='L')ctl('laser',st.laser?0:1);
  else if(k>='1'&&k<='4')ctl('mode',+k-1);else return;
  e.preventDefault();
};
const modes=['MANUAL','PERSON','MOTION','SCAN'], kinds=['','face','torso','motion','person'];
async function poll(){
  try{
    const r=await fetch('/status',{cache:'no-store'});st=await r.json();
    $$('.m').forEach(b=>b.classList.toggle('on',+b.dataset.mode===st.mode));
    $('#laser').classList.toggle('on',st.laser);
    $('#autofire').classList.toggle('on',st.autoFire);
    $$('[data-t]').forEach(b=>b.classList.toggle('on',!!st[b.dataset.key]));
    $$('input[data-var]').forEach(r=>{if(r!==editing){r.value=st[r.dataset.key];r.nextElementSibling.textContent=st[r.dataset.key];}});
    if(editing!==pan){pan.value=st.panSet;$('#panv').textContent=st.pan.toFixed(1);}
    if(editing!==tilt){tilt.value=st.tiltSet;$('#tiltv').textContent=st.tilt.toFixed(1);}
    if(!st.faceOk&&st.detector!=='espdet-person'){$('#mface').disabled=true;$('#mface').title='no detector in this build';}
    if(st.detector)$('#mface').textContent='Person ('+st.detector+')';
    const tgt=(st.found?`${kinds[st.kind]||'target'} ${st.tx},${st.ty} ${st.tw}x${st.th} s=${st.score}`:(st.fresh?'target (coasting)':'no target'))+(st.faceAge>=0?`  face seen ${st.faceAge<1000?st.faceAge+' ms':(st.faceAge/1000).toFixed(1)+' s'} ago`:'');
    $('#stat').innerHTML=`mode ${modes[st.mode]}${st.scanning?' / scanning':''}\npan ${st.pan.toFixed(1)}  tilt ${st.tilt.toFixed(1)}\n${tgt}${st.locked?'  <span class="lock">LOCK</span>':''}\n${st.fps} fps  infer ${st.infer} ms  rssi ${st.rssi}\nheap ${(st.heap/1024)|0}k  psram ${(st.psram/1024)|0}k`;
  }catch(e){$('#stat').textContent='disconnected';}
  setTimeout(poll,300);
}
poll();
</script></body></html>
)HTML";
