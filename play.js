/* Beginner guidance and playful layer: term hints, labs, glossary cards, challenge, XP and badges. */
window.PLAY = app => {
  'use strict';
  const {state,save,lessons,C,icon,chip,title,esc,toast,$,lessonBy}=app, L=window.LEARN, LABS=window.LABS;
  const termBy=k=>L.glossary.find(g=>g.k===k), labBy=id=>LABS.list.find(x=>x.id===id), plainOf=l=>L.plain[l.id]||{level:1};
  const lessonNo=l=>String(lessons.indexOf(l)+1).padStart(2,'0'), groupName=g=>g.title.split('/')[1].trim();
  const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches, canHover=matchMedia('(hover: hover)').matches;
  const pick=(a,n)=>{a=[...a];for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a.slice(0,n);};

  // ---- 进度、经验与徽章：全部由学习记录推算，导入备份后自动一致 ----
  const correct=()=>Object.values(state.answers).filter(a=>a.correct).length;
  const noted=()=>lessons.filter(l=>state.notes[l.id]?.text?.trim()).length;
  const xp=()=>state.done.length*20+correct()*10+state.labs.length*10+noted()*5+(state.primer?15:0)+state.best*2;
  const LEVELS=[[0,'新手上路'],[60,'数据侦探'],[180,'模型学徒'],[360,'评估能手'],[600,'解释高手'],[900,'审计达人']];
  function level(){const x=xp();let i=0;LEVELS.forEach((v,k)=>{if(x>=v[0])i=k;});const next=LEVELS[i+1];return {n:i+1,name:LEVELS[i][1],xp:x,left:next?next[0]-x:0,pct:next?(x-LEVELS[i][0])/(next[0]-LEVELS[i][0])*100:100};}
  const day=d=>d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');
  function touchDay(){const t=day(new Date());if(!state.days.includes(t)){state.days=[...state.days,t].slice(-400);save();}}
  function streak(){let n=0;const d=new Date();if(!state.days.includes(day(d)))d.setDate(d.getDate()-1);while(state.days.includes(day(d))){n++;d.setDate(d.getDate()-1);}return n;}
  const groupDone=g=>lessons.filter(l=>l.group===g).every(l=>state.done.includes(l.id));
  const tests={primer:()=>state.primer,first:()=>state.done.length>0,foundation:()=>groupDone('foundation'),models:()=>groupDone('models'),evaluation:()=>groupDone('evaluation'),practice:()=>groupDone('practice'),all:()=>state.done.length>=lessons.length,quiz5:()=>correct()>=5,quiz30:()=>correct()>=lessons.length,lab3:()=>state.labs.length>=3,laball:()=>state.labs.length>=LABS.list.length,cards:()=>state.flips.length>=20,note3:()=>noted()>=3,streak3:()=>streak()>=3,streak7:()=>streak()>=7,challenge:()=>state.best>=8,perfect:()=>state.best>=10};
  function sync(quiet){const fresh=L.badges.filter(b=>tests[b.id]()&&!state.badges.includes(b.id));if(!fresh.length)return;state.badges.push(...fresh.map(b=>b.id));save();if(!quiet){toast('解锁徽章 '+fresh.map(b=>b.icon+' '+b.name).join('、'));confetti();}}
  function confetti(){
    if(reduced)return;const c=document.createElement('canvas');c.className='confetti';c.width=innerWidth;c.height=innerHeight;document.body.appendChild(c);
    const g=c.getContext('2d'),colors=['#456c59','#d4dfa9','#c47a4e','#d9a441','#243b39'];
    const bits=Array.from({length:80},()=>({x:innerWidth/2+(Math.random()-.5)*160,y:innerHeight*.38,vx:(Math.random()-.5)*15,vy:-Math.random()*12-3,s:5+Math.random()*5,r:Math.random()*6,c:colors[Math.floor(Math.random()*colors.length)]}));let t=0;
    (function tick(){g.clearRect(0,0,c.width,c.height);bits.forEach(p=>{p.x+=p.vx;p.y+=p.vy;p.vy+=.36;p.vx*=.99;p.r+=.2;g.save();g.translate(p.x,p.y);g.rotate(p.r);g.globalAlpha=Math.max(0,1-t/85);g.fillStyle=p.c;g.fillRect(-p.s/2,-p.s/2,p.s,p.s*.6);g.restore();});if(++t<90)requestAnimationFrame(tick);else c.remove();})();
  }
  function applyPrefs(){const r=document.documentElement;r.dataset.text=state.prefs.font;r.classList.toggle('beginner-off',!state.prefs.beginner);}

  // ---- 术语提示：正文中每个术语只标注第一次出现 ----
  const patterns=L.glossary.flatMap(g=>g.m.map(w=>({k:g.k,w,ascii:/^[\x20-\x7e]+$/.test(w)}))).sort((a,b)=>b.w.length-a.w.length);
  const wordish=c=>!!c&&/[A-Za-z0-9_.\-]/.test(c);
  function annotate(html,used){
    if(!state.prefs.beginner)return html;
    const doc=new DOMParser().parseFromString('<div>'+html+'</div>','text/html'),root=doc.body.firstElementChild,walker=doc.createTreeWalker(root,NodeFilter.SHOW_TEXT),nodes=[];
    while(walker.nextNode())nodes.push(walker.currentNode);
    nodes.forEach(node=>{
      if(node.parentElement.closest('code,pre,a,th,h1,h2,h3,h4,button'))return;let s=node.nodeValue;const out=[];
      for(;;){
        let best=null;
        for(const p of patterns){if(used.has(p.k))continue;let at=s.indexOf(p.w);while(at!==-1&&p.ascii&&(wordish(s[at-1])||wordish(s[at+p.w.length])))at=s.indexOf(p.w,at+1);if(at!==-1&&(!best||at<best.at))best={at,p};}
        if(!best)break;
        const b=doc.createElement('button');b.type='button';b.className='term';b.dataset.term=best.p.k;b.textContent=best.p.w;
        out.push(doc.createTextNode(s.slice(0,best.at)),b);used.add(best.p.k);s=s.slice(best.at+best.p.w.length);
      }
      if(out.length){out.push(doc.createTextNode(s));node.replaceWith(...out);}
    });
    return root.innerHTML;
  }
  const pop=document.createElement('div');pop.id='term-pop';pop.hidden=true;pop.setAttribute('role','tooltip');document.body.appendChild(pop);
  let popFor=null,popTimer;
  function showTerm(btn){
    const g=termBy(btn.dataset.term);if(!g)return;const l=lessonBy(g.l),here=app.route().parts[1]===g.l;
    pop.innerHTML=`<div class="term-pop-head"><b>${esc(g.t)}</b><small>${esc(g.en)}</small></div><p>${esc(g.p)}</p><p class="term-pop-eg">例：${esc(g.e)}</p><div class="term-pop-foot"><a href="#glossary?term=${g.k}">翻开术语卡 →</a>${l&&!here?`<a href="#chapter/${l.id}">第 ${lessonNo(l)} 课细讲 →</a>`:''}</div>`;
    pop.hidden=false;const r=btn.getBoundingClientRect(),w=pop.offsetWidth,h=pop.offsetHeight;let y=r.bottom+8;if(y+h>innerHeight-10)y=r.top-h-8;
    pop.style.left=Math.max(10,Math.min(r.left+r.width/2-w/2,innerWidth-w-10))+'px';pop.style.top=Math.max(10,y)+'px';popFor=btn;
  }
  function hideTerm(){pop.hidden=true;popFor=null;clearTimeout(popTimer);}

  // ---- 章节内的新手组件 ----
  const levelChip=l=>`<span class="chip level-${plainOf(l).level}">${L.levels[plainOf(l).level]}</span>`;
  function plainCard(l){
    const p=L.plain[l.id];if(!p||!state.prefs.beginner)return '';
    return `<aside class="plain-card" aria-label="白话导读"><div class="plain-head">${icon('sprout',16)}<b>先用白话理解</b><span>约 ${l.minutes} 分钟 · ${L.levels[p.level]}</span></div><p class="plain-hook">${esc(p.hook)}</p><p class="plain-analogy"><b>打个比方</b>${esc(p.analogy)}</p>${p.lab?`<a class="plain-lab" href="#chapter/${l.id}" data-scroll="lab">${icon('flask',14)}本课有一个互动实验：${esc(labBy(p.lab).title)} ↓</a>`:''}</aside>`;
  }
  const labSection=l=>{const p=L.plain[l.id];return p?.lab?`<section class="lesson-section" id="lab"><h2>动手试一试</h2><div class="lab-host" data-lab="${p.lab}"></div></section>`:'';};
  // 选项顺序按章节固定打乱，正确答案不再总是第一个
  function order(l){let h=7;for(const ch of l.id)h=(h*31+ch.charCodeAt(0))>>>0;const idx=l.quiz.options.map((_,i)=>i);for(let i=idx.length-1;i>0;i--){h=(Math.imul(h,1664525)+1013904223)>>>0;const j=(h>>>16)%(i+1);[idx[i],idx[j]]=[idx[j],idx[i]];}return idx;}
  function quiz(l,effect=''){
    const a=state.answers[l.id],solved=a&&(a.correct||a.revealed),wrongs=a?(a.wrongs||(solved?[]:[a.selected])):[];
    const options=order(l).map((i,pos)=>`<button class="quiz-option ${solved&&i===l.quiz.answer?'correct':wrongs.includes(i)?'wrong':''}" data-quiz="${l.id}" data-choice="${i}" ${solved||wrongs.includes(i)?'disabled':''}><span class="option-letter">${'ABCD'[pos]}</span>${esc(l.quiz.options[i])}</button>`).join('');
    const feedback=!a?'<p class="quiz-hint">选一个你认为对的答案。答错可以再试，不扣分。</p>':a.correct?`<p class="quiz-feedback"><b>回答正确${wrongs.length?'':'，一次就对'}！</b>${esc(l.quiz.explanation)}</p><button class="btn text" data-quiz-reset="${l.id}">重新作答</button>`:a.revealed?`<p class="quiz-feedback wrong"><b>正确答案已标出。</b>${esc(l.quiz.explanation)}</p><button class="btn text" data-quiz-reset="${l.id}">重新作答</button>`:`<p class="quiz-feedback wrong"><b>还差一点，再想想。</b>可以回到本课开头的白话导读再看一眼。</p><button class="btn text" data-quiz-reveal="${l.id}">直接看答案</button>`;
    return `<div class="quiz-box ${effect}" id="quiz"><div class="eyebrow">CHECK YOUR UNDERSTANDING / 自测</div><h3>${esc(l.quiz.question)}</h3><div class="quiz-options">${options}</div>${feedback}</div>`;
  }

  // ---- 首页组件 ----
  function journey(){
    const next=lessons.find(l=>!state.done.includes(l.id));
    return `<div class="journey">${C.groups.map((g,i)=>{const ls=lessons.filter(l=>l.group===g.id),done=ls.filter(l=>state.done.includes(l.id)).length;
      return `<div class="journey-row"><a class="journey-label" href="#chapter/${ls[0].id}"><span>PART 0${i+1}</span><b>${esc(groupName(g))}</b><small>${done} / ${ls.length} 已读</small></a><div class="journey-nodes">${ls.map(l=>`<a class="node ${state.done.includes(l.id)?'done':l===next?'next':''}" href="#chapter/${l.id}" data-node="${l.id}" aria-label="第 ${lessonNo(l)} 课 ${esc(l.title)}${state.done.includes(l.id)?'，已读':''}">${state.done.includes(l.id)?icon('check',15):lessonNo(l)}</a>`).join('')}</div></div>`;}).join('')}<div class="journey-caption" id="journey-caption">${next?`下一站：第 ${lessonNo(next)} 课「${esc(next.title)}」。把鼠标移到任意一站可以预览。`:'30 站全部走完了，了不起！'}</div></div>`;
  }
  function nodeCaption(id){const l=lessonBy(id),box=$('#journey-caption');if(l&&box)box.innerHTML=`<b>第 ${lessonNo(l)} 课 · ${esc(l.title)}</b>　${L.levels[plainOf(l).level]} · 约 ${l.minutes} 分钟${state.done.includes(l.id)?' · 已读':''}<br>${esc(L.plain[l.id]?.hook||l.subtitle)}`;}
  function flipCard(g,extra=''){const l=lessonBy(g.l);return `<div class="term-card ${extra}" id="term-${g.k}"><button type="button" class="flip ${state.flips.includes(g.k)&&!extra?'seen':''}" data-flip="${g.k}" aria-pressed="false"><span class="flip-face front"><small>${esc(g.c)}</small><b>${esc(g.t)}</b><i>${esc(g.en)}</i><em>点一下翻面</em></span><span class="flip-face back"><span>${esc(g.p)}</span><small>例：${esc(g.e)}</small></span></button>${l?`<a class="flip-link" href="#chapter/${l.id}">第 ${lessonNo(l)} 课细讲 →</a>`:''}</div>`;}
  function status(){
    const lv=level(),s=streak(),steps=[[state.primer,'#start','花 5 分钟读零基础入门','不用任何基础，先建立直觉'],[state.labs.length>0,'#labs','动手玩一个互动实验','拖一拖滑块，比读十遍定义管用'],[state.done.length>0,'#chapter/'+lessons[0].id,'读完第一课并做自测','每课都有白话导读和术语提示']];
    const next=lessons.find(l=>!state.done.includes(l.id)),today=L.glossary[Math.floor(Date.now()/864e5)%L.glossary.length];
    const first=steps.every(x=>x[0])?(next?`<a class="status-card next-card" href="#chapter/${next.id}"><div class="eyebrow">NEXT UP / 下一课</div><h3>第 ${lessonNo(next)} 课 · ${esc(next.title)}</h3><p>${esc(L.plain[next.id]?.hook||next.subtitle)}</p><span class="card-go">继续学习 ${icon('arrow',13)}</span></a>`:`<a class="status-card next-card" href="#challenge"><div class="eyebrow">ALL DONE / 全部读完</div><h3>30 课已全部读完</h3><p>去闯关挑战检验一下，或者回到笔记整理自己的理解。</p><span class="card-go">去闯关 ${icon('arrow',13)}</span></a>`):`<div class="status-card"><div class="eyebrow">FIRST STEPS / 新手三步</div><h3>第一次来？按这三步开始</h3><ol class="first-steps">${steps.map(([ok,href,t,d])=>`<li class="${ok?'ok':''}"><a href="${href}"><span class="step-mark">${ok?icon('check',13):''}</span><span><b>${t}</b><small>${d}</small></span>${icon('arrow',13)}</a></li>`).join('')}</ol></div>`;
    return `<section class="status-grid reveal">${first}<a class="status-card level-card" href="#notebook"><div class="eyebrow">YOUR PROGRESS / 我的进度</div><div class="level-line"><span class="level-ring" style="--p:${lv.pct}"><b>Lv.${lv.n}</b></span><div><h3>${lv.name}</h3><p>${lv.xp} XP${lv.left?` · 再得 ${lv.left} XP 升级`:' · 已到最高等级'}</p></div></div><div class="mini-stats"><span><b>${s}</b>天连续学习</span><span><b>${state.done.length}</b>课已读</span><span><b>${state.badges.length}</b>枚徽章</span></div></a><div class="status-card word-card"><div class="eyebrow">WORD OF THE DAY / 今日一词</div>${flipCard(today,'compact')}</div></section>`;
  }
  const labCard=x=>`<a class="lab-card ${state.labs.includes(x.id)?'played':''}" href="#lab/${x.id}"><span class="lab-card-icon">${icon(x.icon,20)}</span><h3>${esc(x.title)}</h3><p>${esc(x.desc)}</p><span class="card-go">${state.labs.includes(x.id)?'再玩一次':'开始实验'} ${icon('arrow',13)}</span></a>`;
  const labTeaser=()=>`<div class="lab-grid">${LABS.list.filter(x=>['censor','km','cindex','shap'].includes(x.id)).map(labCard).join('')}</div>`;
  const badgeWall=()=>`<div class="badge-wall">${L.badges.map(b=>`<div class="badge ${state.badges.includes(b.id)?'earned':''}" title="${esc(b.desc)}"><span>${b.icon}</span><b>${esc(b.name)}</b><small>${esc(b.desc)}</small></div>`).join('')}</div>`;
  function sidebarBox(){const lv=level(),s=streak();return `<div class="progress-box"><a class="level-row" href="#notebook"><span class="level-badge">Lv.${lv.n}</span><span class="level-text"><b>${lv.name}</b><small>${lv.xp} XP${lv.left?` · 差 ${lv.left} 升级`:''}</small></span>${s?`<span class="streak" title="连续学习 ${s} 天">${icon('flame',13)}${s}</span>`:''}</a><div class="progress-track xp"><i style="width:${lv.pct}%"></i></div><div class="row"><span>已读章节</span><span>${state.done.length} / ${lessons.length}</span></div><div class="progress-track"><i style="width:${state.done.length/lessons.length*100}%"></i></div></div>`;}
  const topTools=()=>`<button class="icon-button tool-toggle ${state.prefs.beginner?'on':''}" data-beginner aria-pressed="${state.prefs.beginner}" title="新手模式：白话导读与术语提示" aria-label="切换新手模式">${icon('sprout',18)}</button><button class="icon-button" data-font title="调整正文字号" aria-label="调整正文字号">${icon('type',18)}</button>`;

  // ---- 零基础入门 ----
  let step=0;
  function start(params){if(params.has('step'))step=Math.max(0,Math.min(L.primer.length-1,Number(params.get('step'))-1||0));return `<div class="primer" id="primer">${startView()}</div>`;}
  function startView(){
    const s=L.primer[step],last=step===L.primer.length-1;
    return `<div class="page-title"><div class="eyebrow">ZERO TO ONE / 零基础入门</div><h1>5 分钟，先建立直觉</h1><p>不需要统计或编程基础。一共 ${L.primer.length} 步，每一步只讲一件事，大多配有一个可以动手的小实验。</p></div><ol class="primer-dots">${L.primer.map((x,i)=>`<li><button type="button" class="${i===step?'now':i<step?'past':''}" data-step="${i}" aria-label="第 ${i+1} 步：${esc(x.title)}" ${i===step?'aria-current="step"':''}>${i<step?icon('check',13):i+1}</button></li>`).join('')}</ol><section class="primer-card"><div class="primer-count">第 ${step+1} 步 / 共 ${L.primer.length} 步</div><h2>${esc(s.title)}</h2><div class="prose">${s.body}</div>${s.lab?`<div class="lab-host" data-lab="${s.lab}"></div>`:''}${s.tip?`<p class="primer-tip">${icon('bulb',15)}${esc(s.tip)}</p>`:''}${s.routes?`<div class="route-grid">${s.routes.map(r=>`<div class="route-card"><h3>${esc(r.title)}</h3><p>${esc(r.desc)}</p><ol>${r.steps.map(id=>`<li><a href="#chapter/${id}">${esc(lessonBy(id).title)}</a></li>`).join('')}</ol><a class="btn small" href="#chapter/${r.steps[0]}">从这里开始 ${icon('arrow',13)}</a></div>`).join('')}</div>`:''}</section><div class="primer-nav"><button type="button" class="btn" data-step="${step-1}" ${step?'':'disabled'}>上一步</button>${last?`<a class="btn primary" href="#chapter/${lessons[0].id}">从第一课开始 ${icon('arrow',15)}</a>`:`<button type="button" class="btn primary" data-step="${step+1}">我懂了，下一步 ${icon('arrow',15)}</button>`}</div>`;
  }
  function goStep(i){step=Math.max(0,Math.min(L.primer.length-1,i));if(step===L.primer.length-1&&!state.primer){state.primer=true;touchDay();save();sync();app.chrome();}$('#primer').innerHTML=startView();mountLabs();window.scrollTo({top:0,behavior:'auto'});$('#main').focus({preventScroll:true});}

  // ---- 互动实验室 ----
  const labsPage=()=>title('HANDS-ON LABS / 互动实验室','先动手，再读定义',`${LABS.list.length} 个小实验，用几条示意数据把抽象概念变成看得见、拖得动的东西。数据是为教学编的，不是项目结果。`)+`<div class="lab-grid wide">${LABS.list.map(labCard).join('')}</div><div class="source-note">${icon('shield',18)}<div><strong>实验里的数字都是示意。</strong><p>它们只用来演示概念怎么运作。项目真实的图表和数值，请到结果图谱和对应章节查看。</p></div></div>`;
  function labPage(id){
    const x=labBy(id);if(!x)return null;const l=lessonBy(x.lesson),i=LABS.list.indexOf(x),next=LABS.list[(i+1)%LABS.list.length];
    return `<div class="page-title"><div class="eyebrow">HANDS-ON LAB ${String(i+1).padStart(2,'0')} / 互动实验</div><h1>${esc(x.title)}</h1><p>${esc(x.desc)}</p></div><div class="lab-host" data-lab="${x.id}"></div><div class="takeaways"><h3>这个实验想让你带走的</h3><ul>${x.takeaways.map(t=>`<li>${esc(t)}</li>`).join('')}</ul></div><div class="button-row"><a class="btn primary" href="#chapter/${l.id}">${icon('book',15)}去读第 ${lessonNo(l)} 课：${esc(l.title)}</a><a class="btn" href="#lab/${next.id}">下一个实验：${esc(next.title)} ${icon('arrow',14)}</a><a class="btn" href="#labs">全部实验</a></div>`;
  }
  function mountLabs(){document.querySelectorAll('[data-lab]:not([data-ready])').forEach(h=>{h.dataset.ready='1';LABS.mount(h,h.dataset.lab,explored);});}
  function explored(id){if(state.labs.includes(id))return;state.labs.push(id);touchDay();save();toast('实验已探索 · +10 XP');sync();app.chrome();}

  // ---- 术语卡片 ----
  let gq='',gcat='';
  function glossary(params){gq='';gcat='';return title(`${L.glossary.length} TERMS / FLASHCARDS`,'术语卡片','每张卡正面是术语，点一下翻到背面看白话解释和例子。读正文时遇到带虚线的词，也可以直接点开。')+`<div class="filter-panel"><input id="glossary-query" class="filter-search" type="search" placeholder="搜索术语、英文或解释…" aria-label="搜索术语"><div class="tab-row" id="glossary-cats">${['',...L.categories].map(c=>`<button type="button" class="tab ${c?'':'active'}" data-gcat="${c}">${c||'全部'}</button>`).join('')}</div></div><div id="glossary-results"></div>`;}
  function updateGlossary(){const q=gq.toLowerCase(),gs=L.glossary.filter(g=>(!gcat||g.c===gcat)&&(!q||(g.t+g.en+g.p+g.m.join(' ')).toLowerCase().includes(q)));$('#glossary-results').innerHTML=`<div class="result-count"><span>显示 ${gs.length} / ${L.glossary.length} 个术语</span><span id="flip-count">已翻开 ${state.flips.length} 张</span></div>${gs.length?`<div class="term-grid">${gs.map(g=>flipCard(g)).join('')}</div>`:'<div class="empty-state"><h3>没有找到这个术语</h3>换一个说法，或者用页面顶部的搜索查找全部章节。</div>'}`;}
  function flip(btn){const on=!btn.classList.contains('flipped');btn.classList.toggle('flipped',on);btn.setAttribute('aria-pressed',on);const k=btn.dataset.flip;if(on&&!state.flips.includes(k)){state.flips.push(k);save();sync();const n=$('#flip-count');if(n)n.textContent=`已翻开 ${state.flips.length} 张`;}}

  // ---- 闯关挑战 ----
  let run=null;
  function newRun(){
    const qs=pick(lessons,6).map(l=>{const o=pick(l.quiz.options.map((t,i)=>({t,ok:i===l.quiz.answer})),9);return {kind:`第 ${lessonNo(l)} 课 · ${l.title}`,q:l.quiz.question,options:o,explain:l.quiz.explanation,link:'#chapter/'+l.id,linkText:'回到这一课'};});
    const ts=pick(L.glossary,4).map(g=>{const o=pick([g,...pick(L.glossary.filter(x=>x.k!==g.k&&x.c===g.c),3)],9).map(x=>({t:x.t,ok:x.k===g.k}));return {kind:'术语配对',q:'下面这句白话，说的是哪个术语？',quote:g.p,options:o,explain:`${g.t}：${g.e}`,link:'#glossary?term='+g.k,linkText:'翻开术语卡'};});
    run={qs:pick([...qs,...ts],10),i:0,score:0,combo:0,best:0,picked:null,missed:[]};
  }
  const challenge=()=>{run=null;return `<div id="challenge">${challengeView()}</div>`;};
  function challengeView(){
    if(!run)return title('QUIZ CHALLENGE / 闯关挑战','十道题，检验一下','每轮从 30 道章节自测和术语卡里随机抽 10 题。连续答对有连击，答错会立刻告诉你为什么。')+`<div class="challenge-intro"><div class="challenge-best"><b>${state.best}</b><span>/ 10　历史最佳</span></div><button type="button" class="btn primary" data-ch="start">${icon('play',15)}开始闯关</button><p>没有时间限制，慢慢想。答对 8 题以上解锁徽章。</p></div>`;
    if(run.i>=run.qs.length){const stars=run.score>=9?3:run.score>=7?2:run.score>=5?1:0;return `<div class="challenge-result"><div class="stars" aria-label="${stars} 颗星">${[0,1,2].map(i=>`<span class="${i<stars?'on':''}">★</span>`).join('')}</div><h1>${run.score} / 10</h1><p>${run.score===10?'满分通关，太稳了！':run.score>=8?'很扎实！错的地方再回头看一眼就好。':run.score>=5?'已经掌握了一半以上，继续加油。':'没关系，这些题本来就有难度。回到对应章节读一读白话导读再来。'}　最高连击 ${run.best}</p>${run.missed.length?`<div class="missed"><h3>值得回看的题</h3>${run.missed.map(q=>`<a class="source-link" href="${q.link}">${icon('book',16)}<span class="source-name">${esc(q.q)}</span><span class="source-category">${esc(q.kind)}</span>${icon('arrow',13)}</a>`).join('')}</div>`:''}<div class="button-row"><button type="button" class="btn primary" data-ch="start">再来一轮</button><a class="btn" href="#course">回到学习路径</a></div></div>`;}
    const q=run.qs[run.i],done=run.picked!==null;
    return `<div class="challenge-bar"><span>第 ${run.i+1} / ${run.qs.length} 题</span><div class="progress-track"><i style="width:${run.i/run.qs.length*100}%"></i></div><span class="combo ${run.combo>1?'hot':''}">${run.combo>1?icon('flame',13)+run.combo+' 连击':'得分 '+run.score}</span></div><div class="quiz-box challenge-q"><div class="eyebrow">${esc(q.kind)}</div><h3>${esc(q.q)}</h3>${q.quote?`<blockquote>${esc(q.quote)}</blockquote>`:''}<div class="quiz-options">${q.options.map((o,i)=>`<button class="quiz-option ${done?(o.ok?'correct':i===run.picked?'wrong':''):''}" data-ch-pick="${i}" ${done?'disabled':''}><span class="option-letter">${'ABCD'[i]}</span>${esc(o.t)}</button>`).join('')}</div>${done?`<p class="quiz-feedback ${q.options[run.picked].ok?'':'wrong'}"><b>${q.options[run.picked].ok?'答对了！':'这题答错了。'}</b>${esc(q.explain)}</p><div class="button-row"><button type="button" class="btn primary" data-ch="next">${run.i===run.qs.length-1?'看结果':'下一题'} ${icon('arrow',14)}</button><a class="btn" href="${q.link}">${q.linkText}</a></div>`:''}</div>`;
  }
  function challengeAct(b){
    if(b.dataset.ch==='start')newRun();
    else if(b.dataset.ch==='next'){run.i++;run.picked=null;if(run.i>=run.qs.length){touchDay();if(run.score>state.best)state.best=run.score;save();if(run.score>=8)confetti();sync();app.chrome();}}
    else{const i=Number(b.dataset.chPick),q=run.qs[run.i];run.picked=i;if(q.options[i].ok){run.score++;run.combo++;run.best=Math.max(run.best,run.combo);}else{run.combo=0;run.missed.push(q);}}
    $('#challenge').innerHTML=challengeView();
  }

  // ---- 渲染后的收尾：实验、滚动进度、目录高亮、入场动画 ----
  const bar=document.createElement('div');bar.id='read-bar';bar.innerHTML='<i></i>';document.body.appendChild(bar);
  let observers=[];
  function afterRender(path,lesson){
    hideTerm();observers.forEach(o=>o.disconnect());observers=[];mountLabs();bar.classList.toggle('on',path==='chapter');onScroll();
    if(path==='glossary'){updateGlossary();const k=app.route().params.get('term'),card=k&&document.getElementById('term-'+k);if(card){card.classList.add('focus');const b=card.querySelector('.flip');if(!b.classList.contains('flipped'))flip(b);requestAnimationFrame(()=>card.scrollIntoView({block:'center'}));}}
    if(lesson){touchDay();if(window.IntersectionObserver){const links=[...document.querySelectorAll('.lesson-rail [data-scroll]')];const spy=new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting)links.forEach(a=>a.classList.toggle('active',a.dataset.scroll===e.target.id));}),{rootMargin:'-18% 0px -72% 0px'});links.forEach(a=>{const t=document.getElementById(a.dataset.scroll);if(t)spy.observe(t);});observers.push(spy);}}
    const items=[...document.querySelectorAll('.reveal')];
    if(reduced||!window.IntersectionObserver)items.forEach(e=>e.classList.add('in'));else{const io=new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target);}}),{rootMargin:'0px 0px -6% 0px'});items.forEach(e=>io.observe(e));observers.push(io);}
    if(!reduced)document.querySelectorAll('[data-count]').forEach(el=>{const to=Number(el.dataset.count),t0=performance.now();(function tick(now){const k=Math.min(1,(now-t0)/800);el.textContent=Math.round(to*(1-Math.pow(1-k,3))).toLocaleString('en-US');if(k<1)requestAnimationFrame(tick);})(t0);});
  }
  function onScroll(){if(!bar.classList.contains('on'))return;const max=document.documentElement.scrollHeight-innerHeight;bar.firstChild.style.width=(max>0?Math.min(100,scrollY/max*100):0)+'%';}
  function searchHits(needle){
    const hits=[];L.glossary.forEach(g=>{if((g.t+' '+g.en+' '+g.m.join(' ')).toLowerCase().includes(needle))hits.push({title:g.t,type:'术语卡片 · '+g.c,url:'#glossary?term='+g.k,snippet:g.p,rank:0});});
    LABS.list.forEach(x=>{if((x.title+' '+x.desc).toLowerCase().includes(needle))hits.push({title:x.title,type:'互动实验',url:'#lab/'+x.id,snippet:x.desc,rank:0});});return hits;
  }

  document.addEventListener('click',e=>{
    const t=e.target.closest('[data-term]');
    if(t){e.preventDefault();if(popFor===t)hideTerm();else showTerm(t);return;}
    if(!pop.hidden&&!e.target.closest('#term-pop'))hideTerm();
    const b=e.target.closest('button,a');if(!b)return;
    if(b.dataset.flip)flip(b);
    if(b.dataset.step!==undefined)goStep(Number(b.dataset.step));
    if(b.dataset.ch||b.dataset.chPick!==undefined)challengeAct(b);
    if(b.dataset.gcat!==undefined){gcat=b.dataset.gcat;document.querySelectorAll('#glossary-cats .tab').forEach(x=>x.classList.toggle('active',x===b));updateGlossary();}
    if(b.hasAttribute('data-font')){state.prefs.font=(state.prefs.font+1)%3;save();applyPrefs();toast('正文字号：'+['标准','大','特大'][state.prefs.font]);}
    if(b.hasAttribute('data-beginner')){state.prefs.beginner=!state.prefs.beginner;save();applyPrefs();app.refresh();toast(state.prefs.beginner?'新手模式已开启：显示白话导读和术语提示。':'新手模式已关闭：只显示正文。');}
    if(b.dataset.quiz||b.dataset.quizReset||b.dataset.quizReveal){
      const l=lessonBy(b.dataset.quiz||b.dataset.quizReset||b.dataset.quizReveal);let effect='';
      if(b.dataset.quizReset)delete state.answers[l.id];
      else if(b.dataset.quizReveal)state.answers[l.id]={selected:l.quiz.answer,correct:false,revealed:true,wrongs:state.answers[l.id]?.wrongs||[]};
      else{const choice=Number(b.dataset.choice),prev=state.answers[l.id],wrongs=prev?(prev.wrongs||(prev.correct?[]:[prev.selected])):[],ok=choice===l.quiz.answer;state.answers[l.id]={selected:choice,correct:ok,wrongs:ok?wrongs:[...wrongs,choice]};effect=ok?'pop':'shake';touchDay();if(ok)confetti();}
      save();$('#quiz').outerHTML=quiz(l,effect);sync();app.chrome();
    }
  });
  document.addEventListener('input',e=>{if(e.target.id==='glossary-query'){gq=e.target.value;updateGlossary();}});
  if(canHover){
    document.addEventListener('mouseover',e=>{const n=e.target.closest('[data-node]');if(n)nodeCaption(n.dataset.node);const t=e.target.closest('.term');if(t){clearTimeout(popTimer);popTimer=setTimeout(()=>showTerm(t),180);}else if(e.target.closest('#term-pop'))clearTimeout(popTimer);});
    document.addEventListener('mouseout',e=>{if(e.target.closest('.term,#term-pop')){clearTimeout(popTimer);popTimer=setTimeout(hideTerm,260);}});
  }
  document.addEventListener('focusin',e=>{const n=e.target.closest?.('[data-node]');if(n)nodeCaption(n.dataset.node);});
  document.addEventListener('keydown',e=>{
    if(e.key==='Escape')hideTerm();
    if((e.key==='ArrowLeft'||e.key==='ArrowRight')&&!e.metaKey&&!e.ctrlKey&&!e.altKey&&!e.shiftKey&&!e.target.closest('input,textarea,select,dialog,.code-lines,.lab,[contenteditable]')){const r=app.route();if(r.parts[0]!=='chapter')return;const to=lessons[lessons.findIndex(l=>l.id===r.parts[1])+(e.key==='ArrowRight'?1:-1)];if(to)location.hash='#chapter/'+to.id;}
  });
  window.addEventListener('scroll',()=>{onScroll();if(!pop.hidden)hideTerm();},{passive:true});
  applyPrefs();sync(true);

  return {annotate,plainCard,labSection,levelChip,quiz,journey,status,labTeaser,badgeWall,sidebarBox,topTools,start,labsPage,labPage,glossary,challenge,afterRender,searchHits,level,streak,correct,noted,sync,touchDay,lessonNo};
};
