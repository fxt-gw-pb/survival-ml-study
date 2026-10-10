/* Interactive teaching labs. Every dataset here is a small illustrative toy; none of it is a project result. */
(() => {
  'use strict';
  const INK='#243b39',ACC='#456c59',CLAY='#c47a4e',GREY='#a3aba0',LINE='#dfe3d8',SOFT='#eef1e6',AMBER='#d9a441';
  const f1=n=>(Math.round(n*10)/10).toFixed(1), pct=n=>Math.round(n*100)+'%';
  const width=el=>Math.max(280,Math.min(el.clientWidth||640,760));
  const svg=(w,h,label,body)=>`<svg width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" role="img" aria-label="${label}">${body}</svg>`;
  const text=(x,y,s,o={})=>`<text x="${x}" y="${y}" font-size="${o.size||12}" fill="${o.fill||'#66716b'}" text-anchor="${o.anchor||'start'}" ${o.weight?`font-weight="${o.weight}"`:''}>${s}</text>`;
  const pill=(label,value,tone='')=>`<span class="lab-pill ${tone}"><b>${value}</b>${label}</span>`;
  function frame(host,o){
    host.innerHTML=`<div class="lab"><div class="lab-head"><span class="lab-tag">互动实验</span><h3>${o.title}</h3><span class="lab-demo">示意数据 · 非项目结果</span></div><p class="lab-lead">${o.lead}</p><div class="lab-controls">${o.controls||''}</div><div class="lab-stage" data-stage></div><div class="lab-readout" data-out aria-live="polite"></div><p class="lab-insight" data-tip></p></div>`;
    const q=s=>host.querySelector(s);return {q,stage:q('[data-stage]'),out:q('[data-out]'),tip:q('[data-tip]')};
  }
  // 把指针位置换算成数据坐标，让图本身也能拖
  function drag(stage,toValue,ping){
    let on=false;const move=e=>{const el=stage.querySelector('svg');if(!el)return;const box=el.getBoundingClientRect();toValue((e.clientX-box.left)*el.width.baseVal.value/box.width);};
    stage.addEventListener('pointerdown',e=>{if(e.target.closest('[data-drag]')){on=true;stage.setPointerCapture(e.pointerId);move(e);ping();}});
    stage.addEventListener('pointermove',e=>{if(on)move(e);});
    ['pointerup','pointercancel'].forEach(t=>stage.addEventListener(t,()=>{on=false;}));
  }

  const labs={};

  labs.censor={title:'删失时间线',icon:'clock',lesson:'survival',desc:'拖动目标时间，看每个人在那一刻是“已发生”“确定没发生”还是“不知道”。',
    takeaways:['删失的意思是“还不知道”，不是“没发生”。','目标时间之前就删失的人，在目标时间的结局是未知的。','把他们一律当成“没发生”，会让对照组掺进本不该在的人——这正是原始 pROC 段需要审查的地方。'],
    mount(host,ping){
      const people=[[9,1],[14,0],[20,1],[23,0],[31,0],[41,1],[47,0],[52,1],[59,0],[66,1]];let T=36,naive=false;
      const ui=frame(host,{title:this.title,lead:'每条横线是一个人的随访。<b>●</b> 表示观察到事件，<b>○</b> 表示删失（观察提前结束）。拖动竖线或滑块，改变“目标时间”。',
        controls:`<label class="lab-slider"><span>目标时间 <output data-o></output></span><input type="range" min="6" max="68" step="1" value="${T}" data-i="T" aria-label="目标时间，单位月"></label><label class="lab-check"><input type="checkbox" data-i="naive">改用“简单二分类”：把删失一律当作没发生</label>`});
      const kind=([t,e])=>e&&t<=T?'event':!e&&t<T?'unknown':'free';
      const draw=()=>{
        const w=width(ui.stage),left=44,right=w-18,row=25,h=people.length*row+58,x=t=>left+t/72*(right-left);
        let body='';for(let m=0;m<=72;m+=12)body+=`<line x1="${x(m)}" y1="14" x2="${x(m)}" y2="${h-34}" stroke="${LINE}"/>`+text(x(m),h-16,m+' 月',{anchor:'middle',size:11});
        people.forEach((p,i)=>{const y=28+i*row,k=kind(p),shown=naive&&k==='unknown'?'free':k,color={event:CLAY,free:ACC,unknown:GREY}[shown];
          body+=text(left-10,y+4,'P'+(i+1),{anchor:'end',size:11})+`<line x1="${x(0)}" y1="${y}" x2="${x(p[0])}" y2="${y}" stroke="${color}" stroke-width="6" stroke-linecap="round" ${k==='unknown'&&!naive?'stroke-dasharray="1 9"':''}/>`;
          body+=p[1]?`<circle cx="${x(p[0])}" cy="${y}" r="6.5" fill="${color}"/>`:`<circle cx="${x(p[0])}" cy="${y}" r="6" fill="#fffefa" stroke="${color}" stroke-width="2.5"/>`;
          if(k==='unknown')body+=naive?`<text x="${x(p[0])+13}" y="${y+4}" font-size="11" font-weight="700" fill="${CLAY}">⚠ 其实不知道</text>`:text(x(p[0])+13,y+4,'？之后未知',{size:11,fill:'#8a9086'});});
        body+=`<g data-drag style="cursor:ew-resize"><rect x="${x(T)-14}" y="4" width="28" height="${h-36}" fill="transparent"/><line x1="${x(T)}" y1="8" x2="${x(T)}" y2="${h-34}" stroke="${INK}" stroke-width="2"/><rect x="${x(T)-27}" y="0" width="54" height="19" rx="9.5" fill="${INK}"/><text x="${x(T)}" y="13.5" font-size="11" fill="#fff" text-anchor="middle">${T} 月</text></g>`;
        ui.stage.innerHTML=svg(w,h,`十位研究对象的随访时间线，目标时间 ${T} 月`,body);
        const n={event:0,free:0,unknown:0};people.forEach(p=>n[kind(p)]++);ui.q('[data-o]').textContent=T+' 月';
        ui.out.innerHTML=naive?pill('当作“已发生”',n.event,'clay')+pill('当作“没发生”',n.free+n.unknown,'green')+(n.unknown?pill('其中其实不知道',n.unknown,'warn'):''):pill(`${T} 月前已发生事件`,n.event,'clay')+pill(`${T} 月时确定还没发生`,n.free,'green')+pill('不知道（之前已删失）',n.unknown,'grey');
        ui.tip.innerHTML=n.unknown?(naive?`简单二分类把 <b>${n.unknown}</b> 位“不知道”的人算进了“没发生”。对照组因此多出 ${n.unknown} 人，后面算出的 ROC / AUC 也跟着走样。`:`有 <b>${n.unknown}</b> 人在 ${T} 月之前就离开了观察。他们后来怎样，我们并不知道——处理删失的方法（如 KM、IPCW）就是为这些人准备的。`):'此刻还没有人提前删失，两种做法结果一样。把竖线往右拖，看看差别从哪里开始出现。';
      };
      host.addEventListener('input',e=>{if(e.target.dataset.i==='T')T=+e.target.value;if(e.target.dataset.i==='naive')naive=e.target.checked;ping();draw();});
      drag(ui.stage,px=>{const w=width(ui.stage);T=Math.max(6,Math.min(68,Math.round((px-44)/(w-62)*72)));ui.q('[data-i="T"]').value=T;draw();},ping);
      draw();return draw;
    }};

  labs.km={title:'KM 曲线搭建器',icon:'chart',lesson:'km',desc:'点一下把某个人在“事件”和“删失”之间切换，看生存曲线的台阶怎么变。',
    takeaways:['每发生一次事件，曲线下降一级；下降幅度 = 事件数 ÷ 当时的在险人数。','删失不会让曲线下降，但会让之后的在险人数变少，所以后面的台阶更高。','曲线越靠后，在险人数越少，估计越不稳定。'],
    mount(host,ping){
      const base=[[5,1],[8,1],[12,0],[16,1],[21,0],[24,1],[30,1],[37,0],[44,1],[52,0]];let people=base.map(p=>[...p]);
      const ui=frame(host,{title:this.title,lead:'下面 10 个人按随访时间排好了。点任意一位，把 TA 在 <b>● 事件</b> 和 <b>○ 删失</b> 之间切换。',
        controls:`<div class="lab-people" data-people></div><div class="lab-buttons"><button type="button" class="btn small" data-a="all">全部设为事件</button><button type="button" class="btn small" data-a="reset">恢复原样</button></div>`});
      const draw=()=>{
        ui.q('[data-people]').innerHTML=people.map((p,i)=>`<button type="button" class="lab-person ${p[1]?'is-event':''}" data-p="${i}" aria-pressed="${!!p[1]}" aria-label="第 ${i+1} 位，${p[0]} 月，${p[1]?'事件':'删失'}，点击切换"><i>${p[1]?'●':'○'}</i>${p[0]} 月</button>`).join('');
        let s=1;const steps=[],rows=[];people.forEach(([t,e],i)=>{const n=people.length-i;if(e){const before=s;s*=1-1/n;steps.push({t,before,s});rows.push([t,n,1,`1 − 1/${n} = ${(1-1/n).toFixed(2)}`,pct(s)]);}});
        const w=width(ui.stage),h=250,L=44,R=w-16,T0=14,B=h-34,x=t=>L+t/60*(R-L),y=v=>B-v*(B-T0);
        let body='';[0,.25,.5,.75,1].forEach(v=>{body+=`<line x1="${L}" y1="${y(v)}" x2="${R}" y2="${y(v)}" stroke="${LINE}"/>`+text(L-8,y(v)+4,pct(v),{anchor:'end',size:11});});
        for(let m=0;m<=60;m+=12)body+=text(x(m),h-14,m+' 月',{anchor:'middle',size:11});
        let d=`M${x(0)},${y(1)}`,cur=1;steps.forEach(k=>{d+=` H${x(k.t)} V${y(k.s)}`;cur=k.s;});d+=` H${x(Math.max(...people.map(p=>p[0])))}`;
        body+=`<path d="${d}" fill="none" stroke="${ACC}" stroke-width="2.5" stroke-linejoin="round"/>`;
        people.forEach(([t,e],i)=>{if(!e){const v=steps.filter(k=>k.t<=t).pop()?.s??1;body+=`<line x1="${x(t)}" y1="${y(v)-7}" x2="${x(t)}" y2="${y(v)+7}" stroke="${INK}" stroke-width="2"/>`;}});
        const med=steps.find(k=>k.s<=.5);if(med)body+=`<path d="M${L},${y(.5)} H${x(med.t)} V${B}" fill="none" stroke="${CLAY}" stroke-dasharray="4 4"/>`+text(x(med.t)+6,B-6,'中位生存 '+med.t+' 月',{size:11,fill:CLAY});
        ui.stage.innerHTML=svg(w,h,'KM 生存曲线',body);
        ui.out.innerHTML=`<div class="table-scroll"><table class="data-table lab-table"><thead><tr><th>事件时间</th><th>在险人数</th><th>事件数</th><th>这一步留下的比例</th><th>生存概率</th></tr></thead><tbody>${rows.map(r=>`<tr>${r.map(c=>`<td>${c}</td>`).join('')}</tr>`).join('')||'<tr><td colspan="5">没有事件，曲线保持在 100%。</td></tr>'}</tbody></table></div>`;
        const cens=people.filter(p=>!p[1]).length;
        ui.tip.innerHTML=cens?`现在有 <b>${cens}</b> 人删失（曲线上的小竖线）。他们没有让曲线下降，却让后面的“在险人数”变少了——所以越往后，每个事件造成的台阶越高。${med?'':'曲线还没降到 50%，所以读不出中位生存时间。'}`:'所有人都观察到了事件：每一级台阶正好是 1/10，曲线一直降到 0。把其中几位改回删失，比较一下台阶的高度。';
      };
      host.addEventListener('click',e=>{const b=e.target.closest('[data-p],[data-a]');if(!b)return;if(b.dataset.p)people[b.dataset.p][1]^=1;if(b.dataset.a==='all')people.forEach(p=>p[1]=1);if(b.dataset.a==='reset')people=base.map(p=>[...p]);ping();draw();});
      draw();return draw;
    }};

  labs.hr={title:'风险倍数 ≠ 概率',icon:'branch',lesson:'coxph',desc:'拖动线性预测值，看风险倍数和某个时间点的生存概率怎样一起变化。',
    takeaways:['Cox 模型算出的是相对“基准人”的风险倍数：risk = exp(LP)。','风险倍数不是概率，它可以大于 1。','想得到某个时间点的生存概率，必须借助基线生存曲线：个体生存概率 = 基线生存概率的 risk 次方。'],
    mount(host,ping){
      let lp=.7,T=36;const s0=t=>Math.exp(-Math.pow(t/55,1.3));
      const ui=frame(host,{title:this.title,lead:'灰线是“基准人”的生存曲线，绿线是你正在调整的这个人。模型先算出线性预测值 LP，再变成风险倍数。',
        controls:`<label class="lab-slider"><span>线性预测值 LP <output data-o="lp"></output></span><input type="range" min="-1.5" max="1.5" step="0.1" value="${lp}" data-i="lp" aria-label="线性预测值"></label><label class="lab-slider"><span>想看的时间点 <output data-o="T"></output></span><input type="range" min="12" max="60" step="12" value="${T}" data-i="T" aria-label="时间点，单位月"></label>`});
      const draw=()=>{
        const risk=Math.exp(lp),w=width(ui.stage),h=250,L=44,R=w-16,T0=14,B=h-34,x=t=>L+t/72*(R-L),y=v=>B-v*(B-T0);
        let body='';[0,.25,.5,.75,1].forEach(v=>{body+=`<line x1="${L}" y1="${y(v)}" x2="${R}" y2="${y(v)}" stroke="${LINE}"/>`+text(L-8,y(v)+4,pct(v),{anchor:'end',size:11});});
        for(let m=0;m<=72;m+=12)body+=text(x(m),h-14,m+' 月',{anchor:'middle',size:11});
        const path=fn=>Array.from({length:73},(_,t)=>`${t?'L':'M'}${x(t).toFixed(1)},${y(fn(t)).toFixed(1)}`).join(' ');
        const a=s0(T),b=Math.pow(a,risk);
        body+=`<line x1="${x(T)}" y1="${T0}" x2="${x(T)}" y2="${B}" stroke="${INK}" stroke-dasharray="3 4"/><path d="${path(s0)}" fill="none" stroke="${GREY}" stroke-width="2.5"/><path d="${path(t=>Math.pow(s0(t),risk))}" fill="none" stroke="${ACC}" stroke-width="3"/><circle cx="${x(T)}" cy="${y(a)}" r="5" fill="${GREY}"/><circle cx="${x(T)}" cy="${y(b)}" r="6" fill="${ACC}" stroke="#fff" stroke-width="2"/>`;
        body+=text(R,y(s0(72))-8,'基准人',{anchor:'end',size:11})+text(R,y(Math.pow(s0(72),risk))+(risk>1?16:-8),'这个人',{anchor:'end',size:11,fill:ACC,weight:600});
        ui.stage.innerHTML=svg(w,h,'基准人与个体的生存曲线',body);
        ui.q('[data-o="lp"]').textContent=(lp>0?'+':'')+lp.toFixed(1);ui.q('[data-o="T"]').textContent=T+' 月';
        ui.out.innerHTML=pill('风险倍数 exp(LP)',risk.toFixed(2)+'×',risk>1?'clay':'green')+pill(`基准人 ${T} 月生存率`,pct(a),'grey')+pill(`这个人 ${T} 月生存率`,pct(b),'green');
        ui.tip.innerHTML=Math.abs(lp)<.05?'LP = 0 时风险倍数正好是 1，两条曲线重合：这个人就是“基准人”。':`风险是基准人的 <b>${risk.toFixed(2)} 倍</b>，但 ${T} 月生存率是从 ${pct(a)} 变成 ${pct(b)}，并不是简单地乘或除以 ${risk.toFixed(2)}。倍数怎样变成概率，取决于基线曲线——所以“风险分数”不能直接当“概率”用。`;
      };
      host.addEventListener('input',e=>{if(e.target.dataset.i==='lp')lp=+e.target.value;if(e.target.dataset.i==='T')T=+e.target.value;ping();draw();});
      draw();return draw;
    }};

  labs.lasso={title:'LASSO 的惩罚旋钮',icon:'spark',lesson:'lasso',desc:'把 λ 调大，看不重要的变量怎样被一个个压到 0。',
    takeaways:['λ 越大，惩罚越重，被留下的变量越少。','交叉验证曲线的最低点对应 lambda.min；lambda.1se 更严格，模型更简约。','“算出了筛选结果”和“后面真的用了它”是两回事——本项目默认仍使用人工指定的 sigvar。'],
    mount(host,ping){
      const coef=[.82,-.64,.45,.31,-.22,.12,.07,-.03],names='ABCDEFGH',MIN=.16,SE=.3;let lam=0;
      const dev=l=>1+6*(l-MIN)**2;
      const ui=frame(host,{title:this.title,lead:'8 个示意特征各有一个系数。空心框是没有惩罚时的系数，实心条是加了惩罚之后剩下的。',
        controls:`<label class="lab-slider"><span>惩罚强度 λ <output data-o></output></span><input type="range" min="0" max="0.9" step="0.01" value="0" data-i="lam" aria-label="惩罚强度 lambda"></label><div class="lab-buttons"><button type="button" class="btn small" data-a="${MIN}">跳到 lambda.min</button><button type="button" class="btn small" data-a="${SE}">跳到 lambda.1se</button><button type="button" class="btn small" data-a="0">不惩罚</button></div>`});
      const draw=()=>{
        const shrunk=coef.map(b=>Math.sign(b)*Math.max(Math.abs(b)-lam,0)),kept=shrunk.filter(Boolean).length;
        const w=width(ui.stage),two=w>520,bw=two?w*.58:w,row=24,h1=coef.length*row+28,mid=bw*.54,unit=(bw-mid-16)/.9;
        let bars=`<line x1="${mid}" y1="6" x2="${mid}" y2="${h1-18}" stroke="${GREY}"/>`+text(mid,h1-4,'系数 = 0',{anchor:'middle',size:11});
        coef.forEach((b,i)=>{const y=10+i*row,s=shrunk[i],bx=v=>Math.min(mid,mid+v*unit),bwid=v=>Math.abs(v)*unit;
          bars+=text(8,y+13,'特征 '+names[i],{size:12,fill:s?INK:GREY,weight:s?600:400})+`<rect x="${bx(b)}" y="${y+2}" width="${bwid(b)}" height="15" rx="3" fill="none" stroke="${GREY}" stroke-dasharray="3 3"/>`+(s?`<rect x="${bx(s)}" y="${y+2}" width="${bwid(s)}" height="15" rx="3" fill="${s>0?CLAY:ACC}"/>`:text(mid+(b>0?-8:8),y+14,'已压到 0',{size:11,fill:GREY,anchor:b>0?'end':'start'}));});
        const cw=two?w-bw:w,ch=two?h1:150,cl=34,cr=cw-12,ct=14,cb=ch-30,cx=l=>cl+l/.9*(cr-cl),cy=v=>cb-(v-.9)/3.5*(cb-ct);
        let curve=text(cl,ct-2,'交叉验证误差（示意）',{size:11});curve+=`<path d="${Array.from({length:91},(_,i)=>`${i?'L':'M'}${cx(i/100).toFixed(1)},${cy(dev(i/100)).toFixed(1)}`).join(' ')}" fill="none" stroke="${ACC}" stroke-width="2.5"/>`;
        [[MIN,'min'],[SE,'1se']].forEach(([l,n])=>{curve+=`<line x1="${cx(l)}" y1="${ct+6}" x2="${cx(l)}" y2="${cb}" stroke="${GREY}" stroke-dasharray="3 3"/>`+text(cx(l),cb+14,n,{anchor:'middle',size:11});});
        curve+=`<circle cx="${cx(lam)}" cy="${cy(dev(lam))}" r="6" fill="${CLAY}" stroke="#fff" stroke-width="2"/>`+text(cr,cb+14,'λ →',{anchor:'end',size:11});
        ui.stage.innerHTML=`<div class="lab-split">${svg(bw,h1,'各特征系数随惩罚收缩',bars)}${svg(cw,ch,'交叉验证误差曲线',curve)}</div>`;
        ui.q('[data-o]').textContent=lam.toFixed(2);ui.out.innerHTML=pill('个特征被保留',kept,'green')+pill('个特征被压到 0',8-kept,'grey');
        ui.tip.innerHTML=lam===0?'没有惩罚时 8 个特征全部保留，包括那些系数很小、可能只是噪声的。往右拖动试试。':Math.abs(lam-MIN)<.006?`这是 <b>lambda.min</b>：交叉验证误差最低的位置，保留了 ${kept} 个特征。`:Math.abs(lam-SE)<.006?`这是 <b>lambda.1se</b>：误差仍在最低点的一个标准误之内，但只保留 ${kept} 个特征，模型更简约。`:lam>.8?'惩罚太重，所有特征都出局了，模型什么也没学到——交叉验证误差也明显升高。':`λ = ${lam.toFixed(2)} 时保留 ${kept} 个特征。系数越小的特征越先出局。`;
      };
      host.addEventListener('input',e=>{if(e.target.dataset.i==='lam'){lam=+e.target.value;ping();draw();}});
      host.addEventListener('click',e=>{const b=e.target.closest('[data-a]');if(!b)return;lam=+b.dataset.a;ui.q('[data-i="lam"]').value=lam;ping();draw();});
      draw();return draw;
    }};

  labs.cindex={title:'C-index 配对游戏',icon:'check',lesson:'cindex',desc:'给 6 个人打风险分，看哪些“两两配对”被排对了、哪些根本没法比。',
    takeaways:['C-index = 排对顺序的配对数 ÷ 可以比较的配对数。','两个人里时间较短的那位如果是删失，就不知道谁先出事，这一对不能比较。','把分数方向反过来，C-index 会变成 1 − C：所以一定要先确认“分数越大越危险”。'],
    mount(host,ping){
      const people=[['A',10,1],['B',18,0],['C',25,1],['D',34,1],['E',42,0],['F',55,1]],start=[9,5,4,6,3,1];let score=[...start],note='';
      const ui=frame(host,{title:this.title,lead:'拖动滑块给每个人打“风险分”（越大 = 模型认为越危险）。右边的格子显示每两个人配成一对的结果。',
        controls:`<div class="lab-buttons"><button type="button" class="btn small" data-a="perfect">完美排序</button><button type="button" class="btn small" data-a="random">随机打分</button><button type="button" class="btn small" data-a="flip">反转方向</button><button type="button" class="btn small" data-a="reset">恢复原样</button></div>`});
      ui.stage.innerHTML=`<div class="lab-split"><div class="lab-scores">${people.map((p,i)=>`<label><span><b>${p[0]}</b> ${p[1]} 月 ${p[2]?'●':'○'}</span><input type="range" min="0" max="10" step="1" value="${score[i]}" data-s="${i}" aria-label="${p[0]} 的风险分"><output data-so="${i}"></output></label>`).join('')}</div><div class="lab-pairs" data-pairs></div></div>`;
      const judge=(i,j)=>{const [a,b]=people[i][1]<people[j][1]?[i,j]:[j,i];if(!people[a][2])return {k:'na',why:`${people[a][0]} 在 ${people[a][1]} 月删失，早于 ${people[b][0]} 的 ${people[b][1]} 月：不知道谁先出事，这一对<b>不能比较</b>。`};
        const lead=`${people[a][0]}（${people[a][1]} 月事件）比 ${people[b][0]} 先出事，`;return score[a]>score[b]?{k:'ok',why:lead+`模型给 ${people[a][0]} 的分数也更高：<b>排对了</b>。`}:score[a]===score[b]?{k:'tie',why:lead+'但两人分数相同：<b>算半对</b>。'}:{k:'bad',why:lead+`模型却给 ${people[b][0]} 更高的分：<b>排反了</b>。`};};
      const draw=()=>{
        let ok=0,tie=0,all=0,cells='<span></span>'+people.map(p=>`<span class="pair-head">${p[0]}</span>`).join('');
        people.forEach((p,i)=>{cells+=`<span class="pair-head">${p[0]}</span>`;people.forEach((_,j)=>{if(j<=i){cells+='<span></span>';return;}const r=judge(i,j);if(r.k!=='na'){all++;if(r.k==='ok')ok++;if(r.k==='tie')tie++;}cells+=`<button type="button" class="pair ${r.k}" data-pair="${i},${j}" aria-label="${p[0]} 与 ${people[j][0]}">${{ok:'✓',bad:'✗',tie:'=',na:'–'}[r.k]}</button>`;});});
        ui.q('[data-pairs]').innerHTML=`<div class="pair-grid">${cells}</div><div class="pair-legend"><span class="pair ok">✓</span>排对 <span class="pair bad">✗</span>排反 <span class="pair tie">=</span>同分 <span class="pair na">–</span>不可比</div>`;
        score.forEach((s,i)=>{ui.q(`[data-so="${i}"]`).textContent=s;ui.q(`[data-s="${i}"]`).value=s;});
        const c=(ok+tie/2)/all;ui.out.innerHTML=pill('C-index',c.toFixed(2),c>=.7?'green':c<=.4?'clay':'grey')+pill('对可以比较',all,'grey')+pill('对排对了',ok,'green')+pill('对不可比',15-all,'grey');
        ui.tip.innerHTML=note||(c===1?'所有可比较的配对都排对了，C-index = 1。注意：B 和 E 是删失，他们的分数只影响一部分配对。':c<.5?'C-index 低于 0.5，比瞎猜还差——很可能是方向弄反了。点“反转方向”试试。':'点右边任意一个格子，看这一对为什么算对、算错或不可比。');
      };
      host.addEventListener('input',e=>{if(e.target.dataset.s){score[e.target.dataset.s]=+e.target.value;note='';ping();draw();}});
      host.addEventListener('click',e=>{const b=e.target.closest('[data-a],[data-pair]');if(!b)return;
        if(b.dataset.pair){const [i,j]=b.dataset.pair.split(',').map(Number);note=judge(i,j).why;}
        else{note='';if(b.dataset.a==='perfect')score=[10,8,6,4,2,0];if(b.dataset.a==='random')score=people.map(()=>Math.floor(Math.random()*11));if(b.dataset.a==='flip')score=score.map(s=>10-s);if(b.dataset.a==='reset')score=[...start];}
        ping();draw();});
      draw();return draw;
    }};

  labs.roc={title:'ROC 与判定门槛',icon:'chart',lesson:'roc',desc:'移动判定门槛，看“抓到的”和“误报的”怎样此消彼长，以及 AUC 从哪里来。',
    takeaways:['门槛放低：抓到更多真正出事的人，同时误报也更多。','把所有门槛对应的点连起来就是 ROC 曲线，曲线下的面积是 AUC。','两组分数重叠得越多，AUC 越接近 0.5（等于瞎猜）。','这是普通二分类的 ROC；生存数据还要先处理删失。'],
    mount(host,ping){
      const zn=[-1.6,-1.1,-.8,-.5,-.3,-.1,.1,.3,.6,.9,1.2,1.7],zp=[-1.4,-1,-.7,-.4,-.2,0,.2,.4,.7,1,1.3,1.8];let sep=2.2,thr=5;
      const ui=frame(host,{title:this.title,lead:'上排是后来出事的人，下排是没出事的人，横向位置是模型打的分。分数 ≥ 门槛的人会被判为“高风险”。',
        controls:`<label class="lab-slider"><span>判定门槛 <output data-o="thr"></output></span><input type="range" min="0" max="10" step="0.1" value="${thr}" data-i="thr" aria-label="判定门槛"></label><label class="lab-slider"><span>模型把两组分开的程度 <output data-o="sep"></output></span><input type="range" min="0" max="4" step="0.1" value="${sep}" data-i="sep" aria-label="两组分开的程度"></label>`});
      const draw=()=>{
        const clamp=v=>Math.max(.2,Math.min(9.8,v)),neg=zn.map(z=>clamp(5+z*1.3-sep/2)),pos=zp.map(z=>clamp(5+z*1.3+sep/2));
        const count=t=>({tp:pos.filter(s=>s>=t).length,fp:neg.filter(s=>s>=t).length});const {tp,fp}=count(thr),fn=12-tp,tn=12-fp;
        let wins=0;pos.forEach(p=>neg.forEach(n=>{wins+=p>n?1:p===n?.5:0;}));const auc=wins/144;
        const w=width(ui.stage),two=w>520,sw=two?w-230:w,L=64,R=sw-14,x=s=>L+s/10*(R-L),h=150;
        let strip=`<rect x="${x(thr)}" y="8" width="${R-x(thr)+10}" height="${h-42}" fill="${SOFT}" rx="6"/>`+text(Math.min(x(thr)+8,R-70),22,'判为高风险 →',{size:11,fill:ACC});
        strip+=text(8,58,'出事',{size:12,fill:CLAY,weight:600})+text(8,100,'没出事',{size:12,fill:ACC,weight:600});
        pos.forEach(s=>{strip+=`<circle cx="${x(s)}" cy="54" r="7" fill="${s>=thr?CLAY:'#fffefa'}" stroke="${CLAY}" stroke-width="2"/>`;});
        neg.forEach(s=>{strip+=`<circle cx="${x(s)}" cy="96" r="7" fill="${s>=thr?ACC:'#fffefa'}" stroke="${ACC}" stroke-width="2"/>`;});
        strip+=`<g data-drag style="cursor:ew-resize"><rect x="${x(thr)-14}" y="4" width="28" height="${h-34}" fill="transparent"/><line x1="${x(thr)}" y1="8" x2="${x(thr)}" y2="${h-34}" stroke="${INK}" stroke-width="2"/></g>`;
        for(let s=0;s<=10;s+=2)strip+=text(x(s),h-12,s,{anchor:'middle',size:11});
        const S=two?210:Math.min(w,240),p=28,q=S-8,rx=v=>p+v*(q-p),ry=v=>q-v*(q-p);
        const pts=[...new Set([...pos,...neg])].sort((a,b)=>b-a).map(t=>count(t));
        let roc=`<rect x="${p}" y="${p}" width="${q-p}" height="${q-p}" fill="#fffefa" stroke="${LINE}"/><line x1="${rx(0)}" y1="${ry(0)}" x2="${rx(1)}" y2="${ry(1)}" stroke="${GREY}" stroke-dasharray="4 4"/><path d="M${rx(0)},${ry(0)} ${pts.map(c=>`L${rx(c.fp/12)},${ry(c.tp/12)}`).join(' ')} L${rx(1)},${ry(1)}" fill="none" stroke="${ACC}" stroke-width="2.5" stroke-linejoin="round"/><circle cx="${rx(fp/12)}" cy="${ry(tp/12)}" r="6.5" fill="${CLAY}" stroke="#fff" stroke-width="2"/>`;
        roc+=text((p+q)/2,S+8,'误报比例 →',{anchor:'middle',size:11})+`<text transform="translate(12 ${(q+10)/2}) rotate(-90)" font-size="11" fill="#66716b" text-anchor="middle">抓到的比例 →</text>`;
        ui.stage.innerHTML=`<div class="lab-split">${svg(sw,h,'两组人的模型分数与判定门槛',strip)}${svg(S,S+14,'ROC 曲线',roc)}</div>`;
        ui.q('[data-o="thr"]').textContent=thr.toFixed(1);ui.q('[data-o="sep"]').textContent=sep.toFixed(1);
        ui.out.innerHTML=pill('抓到（灵敏度）',`${tp}/12`,'clay')+pill('漏掉',fn,'grey')+pill('误报',`${fp}/12`,'warn')+pill('正确放过',tn,'green')+pill('AUC',auc.toFixed(2),auc>=.7?'green':'grey');
        ui.tip.innerHTML=sep<.3?'两组分数几乎完全重叠：不管门槛放哪儿，抓到的和误报的比例都差不多，ROC 贴着对角线，AUC ≈ 0.5。':tp===12&&fp===12?'门槛太低：所有人都被判为高风险。一个都没漏，但也全是误报——ROC 上的点在右上角。':tp===0&&fp===0?'门槛太高：谁都没被判为高风险。没有误报，可是一个也没抓到——点在左下角。':`这个门槛抓到 ${tp} 位、误报 ${fp} 位，对应右图的橙色点。AUC 不依赖某一个门槛，它概括的是整条曲线。`;
      };
      host.addEventListener('input',e=>{if(e.target.dataset.i==='thr')thr=+e.target.value;if(e.target.dataset.i==='sep')sep=+e.target.value;ping();draw();});
      drag(ui.stage,px=>{const w=width(ui.stage),sw=w>520?w-230:w;thr=Math.max(0,Math.min(10,Math.round((px-64)/(sw-78)*100)/10));ui.q('[data-i="thr"]').value=thr;draw();},ping);
      draw();return draw;
    }};

  labs.shap={title:'SHAP 拆账：今天通勤要多久',icon:'spark',lesson:'shap',desc:'用通勤时间的生活例子，看 SHAP 怎样把一次预测拆成“基线 + 每个特征的贡献”。',
    takeaways:['每个人的预测 = 基线（平均预测）+ 各特征贡献之和。','贡献是相对“平均情况”说的：没发生的事也可以有贡献。','SHAP 解释的是模型怎么算，不是现实里的因果。','换到本项目：基线是模型输出的平均值，特征是 Age、Surgery 等变量，被解释的是风险分数而不是概率。'],
    mount(host,ping){
      const F=[{n:'下雨',w:10,p:.3},{n:'早高峰出门',w:14,p:.5},{n:'地铁故障',w:20,p:.1},{n:'骑电动车',w:-8,p:.4}];let on=[1,1,0,0];
      const base=25+F.reduce((s,f)=>s+f.w*f.p,0);
      const ui=frame(host,{title:this.title,lead:`一个示意模型预测通勤时间。平均下来是 <b>${f1(base)} 分钟</b>（基线）。勾选今天的情况，看每个条件把预测推高还是拉低。`,
        controls:`<div class="lab-toggles">${F.map((f,i)=>`<label class="lab-check"><input type="checkbox" data-f="${i}" ${on[i]?'checked':''}>${f.n}</label>`).join('')}</div>`});
      const draw=()=>{
        const phi=F.map((f,i)=>f.w*(on[i]-f.p)),pred=base+phi.reduce((a,b)=>a+b,0);
        const w=width(ui.stage),L=w>460?128:104,R=w-50,row=34,h=(F.length+2)*row+26,x=v=>L+(v-10)/65*(R-L);
        let body='';for(let m=10;m<=75;m+=(w>460?10:20))body+=`<line x1="${x(m)}" y1="6" x2="${x(m)}" y2="${h-24}" stroke="${LINE}"/>`+text(x(m),h-8,m+' 分',{anchor:'middle',size:11});
        body+=text(8,25,'基线（平均）',{size:12,fill:INK,weight:600})+`<circle cx="${x(base)}" cy="21" r="6" fill="${INK}"/>`+text(x(base)+11,25,f1(base),{size:12,fill:INK});
        let run=base;F.forEach((f,i)=>{const y=row*(i+1)+8,to=run+phi[i],a=Math.min(x(run),x(to)),up=phi[i]>0;
          body+=`<line x1="${x(run)}" y1="${y-row+18}" x2="${x(run)}" y2="${y+4}" stroke="${GREY}" stroke-dasharray="2 3"/>`+text(8,y+17,(on[i]?'':'没有')+f.n,{size:12,fill:on[i]?INK:'#7d867c',weight:on[i]?600:400})+`<rect x="${a}" y="${y+4}" width="${Math.max(2,Math.abs(x(to)-x(run)))}" height="18" rx="4" fill="${up?CLAY:ACC}"/>`+text(up?x(to)+7:a-7,y+17,(up?'+':'−')+f1(Math.abs(phi[i])),{size:12,fill:up?CLAY:ACC,weight:600,anchor:up?'start':'end'});run=to;});
        const y=row*(F.length+1)+8;body+=`<line x1="${x(run)}" y1="${y-row+22}" x2="${x(run)}" y2="${y+6}" stroke="${GREY}" stroke-dasharray="2 3"/>`+text(8,y+19,'今天的预测',{size:12,fill:INK,weight:600})+`<circle cx="${x(pred)}" cy="${y+14}" r="8" fill="${AMBER}" stroke="#fff" stroke-width="2"/>`+text(x(pred)+13,y+19,f1(pred)+' 分钟',{size:13,fill:INK,weight:700});
        ui.stage.innerHTML=svg(w,h,'从基线到今日预测的贡献瀑布图',body);
        ui.out.innerHTML=`<span class="lab-sum">${f1(base)} ${phi.map(v=>`<b class="${v>0?'up':'down'}">${v>0?'+':'−'} ${f1(Math.abs(v))}</b>`).join(' ')} = <b>${f1(pred)} 分钟</b></span>`;
        const off=F.findIndex((f,i)=>!on[i]&&Math.abs(phi[i])>=1.5);
        ui.tip.innerHTML=off>-1?`注意“没有${F[off].n}”也有贡献（${phi[off]>0?'+':'−'}${f1(Math.abs(phi[off]))}）：因为平均的一天里有 ${pct(F[off].p)} 的可能${F[off].n}，今天没有，自然和平均不一样。SHAP 永远是相对平均情况来拆账的。`:'每一段的长度是这个条件的贡献，橙色把预测推高，绿色把预测拉低。把它们全部加到基线上，正好等于今天的预测。';
      };
      host.addEventListener('input',e=>{if(e.target.dataset.f){on[e.target.dataset.f]=+e.target.checked;ping();draw();}});
      draw();return draw;
    }};

  labs.split={title:'随机种子与数据划分',icon:'branch',lesson:'split',desc:'换一个种子重新抽样，看“随机”为什么能被重现，以及分层抽样保住了什么。',
    takeaways:['种子相同、算法相同，每次抽到的人完全一样——这就是可重现。','换一个种子，抽到的人就变了，评估结果也会有波动。','分层抽样让训练集和测试集的事件比例保持接近。','只有种子相同还不够：抽样算法或取整规则不同，结果仍然不同。'],
    mount(host,ping){
      const N=24,EV=14;let seed=123,strat=true,runs=0,last='';
      const rng=s=>()=>{s|=0;s=s+0x6D2B79F5|0;let t=Math.imul(s^s>>>15,1|s);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};
      const shuffle=(a,r)=>{a=[...a];for(let i=a.length-1;i>0;i--){const j=Math.floor(r()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;};
      const ui=frame(host,{title:this.title,lead:'24 个人（<b>●</b> 14 位事件，<b>○</b> 10 位删失）要按 70% / 30% 分成训练集和测试集。圆圈里的数字是每个人的编号。',
        controls:`<label class="lab-number">随机种子 <input type="number" value="${seed}" min="1" max="9999" data-i="seed" aria-label="随机种子"></label><label class="lab-check"><input type="checkbox" data-i="strat" checked>按事件状态分层</label><div class="lab-buttons"><button type="button" class="btn small" data-a="again">同一个种子再抽一次</button><button type="button" class="btn small" data-a="new">换一个种子</button></div>`});
      const draw=()=>{
        const r=rng(seed),ids=Array.from({length:N},(_,i)=>i);let train;
        if(strat)train=[...shuffle(ids.slice(0,EV),r).slice(0,10),...shuffle(ids.slice(EV),r).slice(0,7)];else train=shuffle(ids,r).slice(0,17);
        const set=new Set(train),tr=ids.filter(i=>set.has(i)),te=ids.filter(i=>!set.has(i)),ev=a=>a.filter(i=>i<EV).length;
        const dot=i=>`<span class="split-dot ${i<EV?'is-event':''}">${i+1}</span>`;
        ui.stage.innerHTML=`<div class="split-boxes"><div class="split-box"><h4>训练集 · ${tr.length} 人</h4><div>${tr.map(dot).join('')}</div></div><div class="split-box test"><h4>测试集 · ${te.length} 人</h4><div>${te.map(dot).join('')}</div></div></div>`;
        const key=tr.join(','),same=runs>0&&key===last;last=key;
        ui.out.innerHTML=pill('训练集事件比例',pct(ev(tr)/tr.length),'green')+pill('测试集事件比例',pct(ev(te)/te.length),'clay')+pill('全体事件比例',pct(EV/N),'grey');
        const gap=Math.abs(ev(tr)/tr.length-ev(te)/te.length);
        ui.tip.innerHTML=(same?`<b>和上一次完全一样。</b>种子 ${seed} 加上同一套抽样规则，抽到的永远是这 17 个人。`:`种子 ${seed}${strat?'，分层抽样':'，不分层'}。`)+' '+(strat?'分层时，事件和删失分别按 70% 抽取，所以两份数据的事件比例很接近。':gap>.15?`不分层时两份数据的事件比例差了 ${pct(gap)}——测试集变得不太像训练集。`:'这次碰巧比例差不多；多换几个种子，会看到不分层时比例忽高忽低。');
      };
      host.addEventListener('input',e=>{if(e.target.dataset.i==='seed'){seed=Math.max(1,Math.min(9999,Math.round(+e.target.value)||1));runs=0;}if(e.target.dataset.i==='strat'){strat=e.target.checked;runs=0;}ping();draw();});
      host.addEventListener('click',e=>{const b=e.target.closest('[data-a]');if(!b)return;if(b.dataset.a==='new'){seed=1+Math.floor(Math.random()*999);ui.q('[data-i="seed"]').value=seed;runs=0;}else runs++;ping();draw();});
      draw();return draw;
    }};

  const order=['censor','km','split','hr','lasso','cindex','roc','shap'];
  window.LABS={
    list:order.map(id=>({id,title:labs[id].title,desc:labs[id].desc,icon:labs[id].icon,lesson:labs[id].lesson,takeaways:labs[id].takeaways})),
    mount(host,id,onExplore){
      const lab=labs[id];if(!lab)return;let fired=false;const draw=lab.mount(host,()=>{if(!fired){fired=true;onExplore?.(id);}});
      const stage=host.querySelector('[data-stage]');let seen=stage.clientWidth;
      if(window.ResizeObserver)new ResizeObserver(()=>{if(Math.abs(stage.clientWidth-seen)>2){seen=stage.clientWidth;draw();}}).observe(stage);
    }
  };
})();
