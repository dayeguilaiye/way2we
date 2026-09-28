/* Throwaway browser prototype. Product runtime remains Flutter + Go. */
(() => {
  const media = {
    'my-avatar': '../assets/plates/my-avatar.png', 'avatar-a': '../assets/plates/avatar-a.png', 'avatar-b': '../assets/plates/avatar-b.png',
    'activity-a': '../assets/plates/activity-a.png', 'activity-b': '../assets/plates/activity-b.png',
    apricot: '../assets/plates/botanical.png', celadon: 'assets/botanical-celadon.png', rose: 'assets/botanical-rose.png',
  };
  const themeNames = { apricot: '暖杏 · 枝叶', celadon: '青瓷 · 叶影', rose: '雾玫 · 花枝' };
  const paths = {
    home: '<path d="m3 10 9-8 9 8v11h-6v-7H9v7H3Z"/>',
    agreement: '<path d="M5 2h10l4 4v16H5Z M15 2v5h4 M8 11h8 M8 15h6"/>',
    shop: '<path d="M3 10v11h18V10 M2 9l3-6h14l3 6c0 4-5 4-5 1 0 3-5 3-5 0 0 3-5 3-5 0-1 3-5 3-5-1Z"/>',
    records: '<path d="M12 3H3v18h15v-8 M7 7h5 M7 11h3 M11 17l2-5 7-7 3 3-7 7-5 2Z"/>',
    bell: '<path d="M5 17h14c-2-2-2-4-2-8a5 5 0 0 0-10 0c0 4 0 6-2 8Z M10 20a2 2 0 0 0 4 0"/>',
    down: '<path d="m6 9 6 6 6-6"/>', right: '<path d="m9 5 7 7-7 7"/>', back: '<path d="m15 4-8 8 8 8"/>',
    plus: '<circle cx="12" cy="12" r="10"/><path d="M12 6v12 M6 12h12"/>',
    add: '<path d="M12 5v14 M5 12h14"/>', minus: '<path d="M5 12h14"/>', check: '<path d="m4 12 5 5L20 6"/>',
    cup: '<path d="M5 9h12v6a5 5 0 0 1-5 5H10a5 5 0 0 1-5-5Z M17 10h2a3 3 0 0 1 0 6h-2 M3 22h17 M8 6c-3-2 3-3 0-5 M13 6c-3-2 3-3 0-5"/>',
    signal: '<path d="M3 20v-4 M8 20v-8 M13 20V8 M18 20V4" stroke-width="3.5"/>',
    wifi: '<path d="M2 8a16 16 0 0 1 20 0 M6 12a10 10 0 0 1 12 0 M10 16a4 4 0 0 1 4 0 M12 20h.01" stroke-width="2.5"/>',
    battery: '<rect x="2" y="5" width="18" height="14" rx="3"/><path d="M22 10v4"/><rect x="5" y="8" width="12" height="8" rx="1" fill="currentColor" stroke="none"/>',
  };
  const icon = name => `<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" class="icon icon-${name}">${paths[name] || paths.records}</svg>`;
  const esc = v => String(v ?? '').replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[c]);
  const ui = { user:'a', sid:'home', tab:'home', page:null, stack:[], modal:null, agreementActive:true, member:'all', shop:'browse', seller:'all', recordMode:'points', recordFilter:'me', orderFilter:'all', offline:false, failNext:false, zoom:1, busy:false, photo:'', guide:0 };
  const app = document.getElementById('app'), stage = document.getElementById('stage'), overlay = document.getElementById('overlay');
  const s = () => Demo.state.spaces[ui.sid];
  const me = () => s()?.members[ui.user];
  const nm = u => Demo.name(s() || {members:{}},u);
  const users = () => Object.keys(s()?.members || {});
  const activeUsers = () => users().filter(u => s().members[u].active);
  const av = (u, activity=false) => `<img class="avatar" src="${media[activity && ['a','b'].includes(u) ? `activity-${u}` : Demo.state.users[u]?.avatar] || media['my-avatar']}" alt="" draggable="false">`;
  const delta = v => `<span class="delta ${v >= 0 ? 'positive' : 'negative'}">${v > 0 ? '+' : v < 0 ? '−' : ''}${Math.abs(v)} <small>分</small></span>`;
  const btn = (label, act, data='', cls='', disabled=false) => `<button type="button" class="button ${cls}" data-act="${act}" data-id="${esc(data)}" ${disabled?'disabled':''}>${label}</button>`;
  const plain = (label,act,data='',cls='') => `<button type="button" class="plain ${cls}" data-act="${act}" data-id="${esc(data)}">${label}</button>`;
  const empty = (title, description='', action='') => `<div class="empty"><h2>${title}</h2><p>${description}</p>${action}</div>`;
  const info = (key,value) => `<div class="info-row"><span>${key}</span><span>${value}</span></div>`;
  const statusText = status => ({pending:'待完成',completed:'已完成',cancelled:'已取消'})[status];
  const photo = (item,cls='') => item.photo ? `<img class="${cls}" src="${esc(item.photo)}" alt="${esc(item.name)}">` : '';
  let toastTimer, modalFocus;
  function toast(message) { const t=document.getElementById('toast');t.textContent=message;t.classList.add('visible');clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.classList.remove('visible'),2600); }
  function theme() {
    const chosen=Demo.state.users[ui.user]?.theme || 'apricot';app.dataset.theme=chosen;app.style.setProperty('--zoom',ui.zoom);app.classList.toggle('large-type',ui.zoom>1);
    app.querySelectorAll('[data-theme-art]').forEach(el=>el.src=media[chosen]);
    app.querySelectorAll('.theme-option').forEach(el=>{el.setAttribute('aria-pressed',el.dataset.id===chosen);el.querySelector('.chosen-mark').innerHTML=el.dataset.id===chosen?icon('check'):'';});
  }
  function statusBar() { return `<div class="status-bar" aria-hidden="true"><span>9:41</span><span class="system-icons">${icon('signal')}${icon('wifi')}${icon('battery')}</span></div>`; }
  function header() { const unread=Demo.state.notices.some(n=>n.recipient===ui.user && n.space===ui.sid && !n.read);return `<header class="app-header">${plain(`<img src="${media['my-avatar']}" alt=""><span>我的</span>`,'page','my','my-entry')}${plain(`<span>${esc(s()?.name || '选择空间')}</span>${icon('down')}`,'page','spaces','space-switch')}${plain(`${icon('bell')}${unread?'<i class="unread"></i>':''}`,'page','inbox','icon-button" aria-label="通知')}</header>`; }
  function nav() { return `<nav class="bottom-nav" aria-label="主导航">${[['home','近况','home'],['agreements','约定','agreement'],['shop','小卖部','shop'],['records','记录','records']].map(([id,label,i])=>`<button class="plain ${ui.tab===id?'active':''}" ${ui.tab===id?'aria-current="page"':''} data-act="tab" data-id="${id}">${icon(i)}<span>${label}</span></button>`).join('')}</nav>`; }
  function top(title,right='') { return `<header class="top-back">${plain(icon('back'),'back','','icon-button" aria-label="返回')}<h1>${title}</h1><div class="right">${right}</div></header>`; }
  const memberOptions = (all=true, currentOnly=false) => `${all?'<option value="all">全部成员</option>':''}${(currentOnly?activeUsers():users()).map(u=>`<option value="${u}">${esc(nm(u))}${s().members[u].active?'':'（已退出）'}</option>`).join('')}`;
  function activity(e) { return plain(`${av(e.actor,true)}<div><time>${esc(e.time)}</time><div class="description">${esc(e.text)}</div>${e.revoked?'<span class="status-label">已撤销</span>':''}</div>${e.delta!==undefined?delta(e.delta):icon('right')}`,'event',e.id,'activity-row'); }
  function pending(o) { return `<article class="surface pending-row"><div class="pending-icon">${icon('cup')}</div>${plain(`<strong>${esc(o.name)} × ${o.quantity}</strong><div class="small-copy muted">${esc(nm(o.seller))}提供 · ${o.buyer===ui.user?'我':esc(nm(o.buyer))}已支付 ${o.total} 分</div>`,'order',o.id,'pending-copy')}<div class="pending-actions">${btn('完成','complete',o.id,'primary small')}${btn('取消','refund',o.id,'small')}</div></article>`; }
  function home() {
    const others=activeUsers().filter(u=>u!==ui.user), other=others[0];
    const balances=`<div class="surface balances">${plain(`${av(ui.user)}<div class="balance-copy"><div class="balance-name">${esc(nm(ui.user))}（我）</div><div class="balance-value">${me().balance}<small>分</small></div><div class="balance-link">查看积分明细 ${icon('right')}</div></div>`,'ledger',ui.user,'balance')}${other?plain(`${av(other)}<div class="balance-copy"><div class="balance-name">${others.length>1?`${others.length} 位成员`:esc(nm(other))}</div><div class="balance-value">${others.length>1?'':s().members[other].balance}${others.length===1?'<small>分</small>':''}</div><div class="balance-link">查看成员 ${icon('right')}</div></div>`,'page','members','balance'):plain(`<div class="balance-copy">邀请对方加入<div class="balance-link">一起开始 ${icon('right')}</div></div>`,'page','members','balance')}</div>`;
    const orders=s().orders.filter(o=>o.status==='pending'&&[o.buyer,o.seller].includes(ui.user));
    return `<section class="home-hero"><img data-theme-art src="${media[Demo.state.users[ui.user].theme]}" alt=""><h1>平凡的日常，<br>也是值得好好记录的生活。</h1><div class="accent-rule"></div><p class="hero-caption">一起，让日子<br>更温柔一点。</p></section>${balances}${btn(`${icon('plus')}<span>记一笔</span>`,'score','','primary block score-main')}<div class="section-heading"><h2>待处理</h2>${plain(`查看全部 ${icon('right')}`,'page','pending')}</div>${orders.length?orders.slice(0,2).map(pending).join(''):`<div class="surface">${empty('暂无待处理交易','可以到小卖部，看看对方准备了什么。',btn('逛小卖部','tab','shop','text'))}</div>`}<div class="section-heading"><h2>空间近况</h2>${plain(`全部记录 ${icon('right')}`,'page','activity')}</div><div class="surface activity-list">${s().events.length?s().events.slice(0,2).map(activity).join(''):empty('日子从这一笔开始','写下第一条约定，把期待变成小小的行动。',btn('创建第一条约定','agreement-form','','primary'))}</div>`;
  }
  function agreements() {
    const list=s().agreements.filter(a=>a.active===ui.agreementActive&&(ui.member==='all'||a.applies.includes(ui.member)));
    return `<div class="page-title"><h1>约定</h1>${btn(`${icon('plus')} 新建`,'agreement-form','','text')}</div><div class="filters"><div class="segmented">${plain('生效中','agreement-filter','active',ui.agreementActive?'selected':'')}${plain('已停用','agreement-filter','inactive',!ui.agreementActive?'selected':'')}</div><label><span class="small-copy muted">适用成员 </span><select data-change="member" aria-label="筛选适用成员">${memberOptions()}</select></label></div>${list.length?list.map(a=>`<article class="surface agreement-card">${plain(`<h2>${esc(a.name)}</h2><span>${delta(a.points)} ${icon('right')}</span>`,'agreement',a.id,'agreement-top')}<div class="agreement-bottom"><p class="small-copy muted">适用于 ${a.applies.map(u=>esc(nm(u))).join('、')}</p>${a.active?btn('记一笔','score',a.id,'primary small'):btn('查看详情','agreement',a.id,'small')}</div></article>`).join(''):empty(ui.agreementActive?'还没有适用的约定':'暂无停用的约定',ui.agreementActive?'一起写下一个容易坚持的小约定吧。':'停用的约定会保留历史。',ui.agreementActive?btn('新建约定','agreement-form','','primary'):'')}<p class="helper">约定可重复记分，修改会保留记录。</p>`;
  }
  function shop() {
    const mine=ui.shop==='mine'; const owners=activeUsers().filter(u=>u!==ui.user);
    const items=s().items.filter(i=>mine?i.owner===ui.user:i.owner!==ui.user&&i.listed&&s().members[i.owner]?.active&&(ui.seller==='all'||i.owner===ui.seller));
    return `<div class="page-title"><h1>小卖部</h1>${mine?btn(`${icon('plus')} 添加`,'item-form','','text'):''}</div><p class="shop-balance">${esc(nm(ui.user))}的可用积分 <strong>${me().balance} 分</strong></p><div class="filters"><div class="segmented">${plain('逛小卖部','shop-mode','browse',!mine?'selected':'')}${plain('我的店铺','shop-mode','mine',mine?'selected':'')}</div>${!mine&&owners.length>1?`<select data-change="seller" aria-label="选择店主"><option value="all">全部店铺</option>${owners.map(u=>`<option value="${u}">${esc(nm(u))}的小卖部</option>`).join('')}</select>`:''}</div>${mine?`<div class="member-line">${av(ui.user)}<div>${esc(nm(ui.user))}的小卖部<p class="small-copy muted">把你的心意，摆上货架。</p></div></div>`:owners.length===1?`<div class="member-line">${av(owners[0])}<span>${esc(nm(owners[0]))}的小卖部</span></div>`:''}${items.length?items.map(i=>`<article class="surface item-row ${i.photo?'':'no-photo'}">${photo(i,'item-photo')}<div>${plain(`<h2>${esc(i.name)}</h2>`,'item',i.id)}<p class="description muted small-copy">${esc(i.description)}</p><p class="price">${i.price} 分 <small>/ 份</small></p>${mine?`<p class="small-copy muted">${i.listed?'已上架':'已下架'}</p><div class="item-actions">${btn('编辑','item-form',i.id,'small')}${btn(i.listed?'下架':'上架','toggle-item',i.id,'small')}</div>`:`<p class="small-copy muted">${esc(nm(i.owner))}提供</p>${btn(`查看详情 ${icon('right')}`,'item',i.id,'text small')}`}</div></article>`).join(''):empty(mine?'给小卖部添一点心意':'货架还在准备中',mine?'一顿早餐、一次陪伴，都可以成为商品。':'等对方上架后，就能用积分购买。',mine?btn('添加商品或服务','item-form','','primary'):'')}`;
  }
  function records() {
    const f=ui.recordFilter==='me'?ui.user:ui.recordFilter;
    const events=s().events.filter(e=>e.delta!==undefined&&(f==='all'||e.target===f));
    const orders=s().orders.filter(o=>(f==='all'||[o.buyer,o.seller].includes(f))&&(ui.orderFilter==='all'||o.status===ui.orderFilter));
    return `<div class="page-title"><h1>记录</h1></div><div class="filters"><div class="segmented">${plain('积分明细','record-mode','points',ui.recordMode==='points'?'selected':'')}${plain('购买记录','record-mode','orders',ui.recordMode==='orders'?'selected':'')}</div><select data-change="record-filter" aria-label="查看谁的记录"><option value="me">我的记录</option>${memberOptions()}</select></div>${ui.recordMode==='points'?`${f!=='all'?`<div class="surface info-box">${info(`${esc(nm(f))}的余额`,`<strong class="refund-value">${s().members[f].balance} 分</strong>`)}</div>`:''}<div class="surface activity-list">${events.length?events.map(activity).join(''):empty('还没有积分变化','每次记分、购买和退款都会记录在这里。')}</div>`:`<div class="filters"><select data-change="order-filter" aria-label="购买状态"><option value="all">全部状态</option><option value="pending">待完成</option><option value="completed">已完成</option><option value="cancelled">已取消</option></select></div>${orders.length?orders.map(orderRow).join(''):empty('暂无购买记录','去小卖部看看吧。',btn('逛小卖部','tab','shop','text'))}`}`;
  }
  function orderRow(o) { return `<article class="surface info-box">${plain(`<div class="info-row"><strong>${esc(o.name)} × ${o.quantity}</strong><span class="badge ${o.status==='pending'?'':'neutral'}">${statusText(o.status)}</span></div><p class="muted small-copy">${esc(nm(o.buyer))}购买 · ${esc(nm(o.seller))}提供</p><div class="info-row"><span>实际支付</span><span>${o.total} 分 ${icon('right')}</span></div>`,'order',o.id,'block')}</article>`; }
  function orderDetail(id) {
    const o=s().orders.find(o=>o.id===id); if(!o)return {title:'购买详情',body:empty('找不到这笔购买')};
    const actionable=[o.buyer,o.seller].includes(ui.user)&&o.status!=='cancelled';
    return {title:'购买详情',body:`<span class="badge ${o.status==='pending'?'':'neutral'}">${statusText(o.status)}</span><div class="detail-hero">${photo(o)}<div><h2>${esc(o.name)} × ${o.quantity}</h2><p class="detail-description">${esc(o.description)}</p></div></div><div class="surface info-box parties">${[[o.buyer,'买方'],[o.seller,'提供方']].map(([u,label])=>`<div class="member-line">${av(u)}<div><p class="small-copy muted">${label}</p>${esc(nm(u))}${u===ui.user?'（我）':''}</div></div>`).join('')}</div><div class="surface info-box"><h2>支付详情</h2>${info('单价',`${o.price} 分 / 份`)}${info('数量',`${o.quantity} 份`)}${info('实际支付',`${o.total} 分`)}${o.status==='cancelled'?info('已退还买方',`${o.total} 分`):''}</div><div class="surface info-box"><h2>购买经过</h2><ol class="timeline">${o.history.map(h=>`<li><time>${esc(h.time)}</time>${esc(nm(h.actor))} · ${h.action}</li>`).join('')}</ol></div>`,footer:actionable?`${o.status==='pending'?btn('确认整笔完成','complete',id,'primary block'):''}${btn(`取消购买并退还 ${o.total} 分`,'refund',id,'block')}`:''};
  }
  function agreementDetail(id) {
    const a=s().agreements.find(a=>a.id===id); if(!a)return{title:'约定详情',body:empty('找不到这条约定')};
    const history=s().events.filter(e=>e.agreement===id&&e.type==='agreement');
    return{title:'约定详情',right:plain('编辑','agreement-form',id,'icon-button'),body:`<span class="badge ${a.active?'':'neutral'}">${a.active?'生效中':'已停用'}</span><h2 class="subheading">${esc(a.name)}</h2>${delta(a.points)}<p class="detail-description helper">${esc(a.description || '暂未填写说明')}</p><div class="surface info-box">${info('适用成员',a.applies.map(u=>esc(nm(u))).join('、'))}${info('记录方式','每次按固定分值记分，可重复')}</div>${btn(a.active?'停用约定':'启用约定','toggle-agreement',id,'block')}<h2 class="subheading">修改记录</h2><div class="surface activity-list">${history.length?history.map(activity).join(''):empty('这条约定还没有修改记录')}</div>`,footer:a.active?btn('记一笔','score',id,'primary block'):''};
  }
  function agreementForm(id) {
    const a=s().agreements.find(a=>a.id===id);
    return {title:a?'编辑约定':'新建约定',body:`<form id="agreement-form" data-submit="agreement" data-id="${esc(id||'')}"><label class="form-field"><span>约定名称</span><input name="name" type="text" maxlength="60" required placeholder="例如：散步 30 分钟" value="${esc(a?.name||'')}"></label><label class="form-field"><span>说明 <span class="muted small-copy">选填</span></span><textarea name="description" maxlength="400" placeholder="说清楚怎样算完成这件事">${esc(a?.description||'')}</textarea></label><div class="form-field"><span class="field-label">适用成员</span><div class="checks">${activeUsers().map(u=>`<label class="check"><input type="checkbox" name="applies" value="${u}" ${a?.applies.includes(u)?'checked':''}>${esc(nm(u))}${u===ui.user?'（我）':''}</label>`).join('')}</div></div><div class="form-field"><span class="field-label">积分</span><div class="radio-row"><label class="check"><input type="radio" name="sign" value="1" ${!a||a.points>0?'checked':''}>加分</label><label class="check"><input type="radio" name="sign" value="-1" ${a?.points<0?'checked':''}>扣分</label></div><input name="points" type="number" min="1" step="1" required aria-label="积分分值" placeholder="输入正整数" value="${a?Math.abs(a.points):''}"></div><p class="muted small-copy">保存后立即生效，过去的记分保留原分值。</p><p class="form-error" role="alert"></p></form>`,footer:`<button class="button primary block" type="submit" form="agreement-form">保存约定</button>`};
  }
  function itemDetail(id) {
    const i=s().items.find(i=>i.id===id); if(!i)return{title:'商品详情',body:empty('找不到这件商品')};
    const mine=i.owner===ui.user;
    return {title:'商品详情',right:mine?plain('编辑','item-form',id,'icon-button'):'',body:`<div class="detail-hero">${photo(i)}<div><h2>${esc(i.name)}</h2><p><strong class="delta">${i.price} 分</strong> / 份</p></div></div><div class="member-line">${av(i.owner)}<span>${esc(nm(i.owner))}的小卖部</span></div><p class="detail-description">${esc(i.description || '店主还没有填写说明。')}</p><p class="helper">购买后立即支付积分，双方都可以确认完成或整笔取消退款。</p>${!i.listed?'<span class="badge neutral">已下架</span>':''}`,footer:mine?btn(i.listed?'下架':'上架','toggle-item',id,'block'):btn('购买','buy',id,'primary block',!i.listed||!s().members[i.owner]?.active)};
  }
  function itemForm(id) {
    const i=s().items.find(i=>i.id===id); ui.photo=i?.photo||'';
    return {title:i?'编辑商品或服务':'添加商品或服务',body:`<form id="item-form" data-submit="item" data-id="${esc(id||'')}"><label class="form-field"><span>名称</span><input name="name" type="text" required maxlength="80" placeholder="例如：准备一份早餐" value="${esc(i?.name||'')}"></label><label class="form-field"><span>说明 <span class="muted small-copy">选填</span></span><textarea name="description" maxlength="600" placeholder="介绍内容，也可以写下提供方式">${esc(i?.description||'')}</textarea></label><div class="form-field"><span class="field-label">图片 <span class="muted small-copy">选填</span></span><div class="photo-edit"><img id="photo-preview" src="${esc(ui.photo)}" alt="商品图片预览" ${ui.photo?'':'hidden'}><label class="button upload-label">选择图片<input type="file" name="photo" accept="image/*" data-change="photo"></label>${btn('移除图片','remove-photo','','text small')}</div><p class="small-copy muted">支持 JPG、PNG 等图片，最多 5 MB。</p></div><label class="form-field"><span>单价（积分 / 份）</span><input name="price" type="number" min="1" step="1" required placeholder="输入正整数" value="${i?.price||''}"></label><p class="form-error" role="alert"></p></form>`,footer:`<button class="button primary block" type="submit" form="item-form">${i?'保存修改':'保存并上架'}</button>`};
  }
  function eventDetail(id) {
    const e=s().events.find(e=>e.id===id);if(!e)return{title:'记录详情',body:empty('找不到这条记录')};
    return {title:'记录详情',body:`<div class="member-line">${av(e.actor)}<div>${esc(nm(e.actor))}<p class="muted small-copy">${esc(e.time)}</p></div></div><p>${esc(e.text)}</p>${e.delta!==undefined?`<div class="surface info-box" style="margin-top:1.2rem">${info('涉及成员',esc(nm(e.target)))}${info('积分变化',delta(e.delta))}</div>`:''}${e.revoked?`<div class="surface info-box">${info('状态','已撤销')}${info('撤销操作人',esc(nm(e.revokedBy)))}${info('撤销时间',esc(e.revokedAt))}${info('回退分值',delta(-e.delta))}</div>`:''}${e.before&&e.after?`<div class="surface info-box"><h2>修改内容</h2>${info('名称',`${esc(e.before.name||'新建')} → ${esc(e.after.name)}`)}${e.after.points!==undefined?`${info('积分',`${e.before.points??'—'} → ${e.after.points} 分`)}${info('适用成员',e.after.applies.map(u=>esc(nm(u))).join('、'))}${info('状态',e.after.active?'生效中':'已停用')}`:''}<p class="small-copy muted detail-description">${esc(e.after.description)}</p></div>`:''}${e.original?btn('查看原记分','event',e.original,'block'):''}`,footer:e.type==='score'&&!e.revoked?btn('撤销这次记分','revoke-confirm',id,'block'):e.order?btn('查看购买详情','order',e.order,'block'):''};
  }
  function spaces() {
    const mine=Object.values(Demo.state.spaces).filter(x=>x.members[ui.user]);
    const invites=Object.values(Demo.state.spaces).flatMap(x=>x.invites.filter(i=>i.target===ui.user&&i.status==='waiting').map(i=>({space:x,invite:i})));
    return {title:'空间',right:plain('我的','page','my','icon-button'),body:`${mine.map(x=>`<div class="surface info-box"><h2>${esc(x.name)}</h2><p class="muted small-copy">${x.members[ui.user].active?`${Object.values(x.members).filter(m=>m.active).length} 位成员`:'已退出 · 余额与历史保留'}</p><div class="item-actions">${btn(x.members[ui.user].active?'进入空间':'重新加入',x.members[ui.user].active?'space':'restore',x.id,'primary')}${x.members[ui.user].active?btn('成员与设置','space-manage',x.id,'text'):''}</div></div>`).join('')}${invites.map(({space:x,invite:i})=>`<div class="surface info-box"><h2>${esc(x.name)}</h2><p>${esc(Demo.name(x,i.actor))}邀请你加入</p><p class="helper">${i.accepted?'已接受，等待现有成员同意。':'接受后，等待现有成员全部同意。'}</p>${btn(i.accepted?'查看加入进度':'接受邀请','invite-answer',`${x.id}|${i.id}`,'primary',i.accepted)}</div>`).join('')}${!mine.length&&!invites.length?empty('创建一个属于你们的空间','可以先创建空间，也可以等待对方的邀请。'):''}${btn(`${icon('plus')} 创建空间`,'new-space','','block')}`};
  }
  function members() {
    return {title:'成员与空间',right:plain('邀请','invite-new','','icon-button'),body:`<h2 class="subheading" style="margin-top:0">${esc(s().name)}</h2><div class="surface info-box">${users().map(u=>`<div class="member-line">${av(u)}<div class="grow">${esc(nm(u))}${u===ui.user?'（我）':''}<p class="small-copy muted">${s().members[u].active?'参与中':'已退出'}</p></div>${plain(`${s().members[u].balance} 分 ${icon('right')}`,'ledger',u)}</div>`).join('')}</div>${s().invites.length?`<h2 class="subheading">加入申请</h2>${s().invites.map(i=>`<div class="surface info-box"><strong>${esc(Demo.state.users[i.target].name)}</strong><p class="small-copy muted">${i.status==='joined'?'已加入空间':i.accepted?'已接受邀请':'等待本人接受'}</p>${activeUsers().map(u=>info(esc(nm(u)),i.approvals.includes(u)?'已同意':'待同意')).join('')}${i.status==='waiting'&&!i.approvals.includes(ui.user)?btn('同意加入','invite-answer',`${ui.sid}|${i.id}`,'primary block'):''}</div>`).join('')}`:''}<div class="surface menu-list">${plain(`我的空间昵称 ${icon('right')}`,'nickname','','menu-row')}${plain(`退出空间 ${icon('right')}`,'leave-confirm','','menu-row')}</div>`};
  }
  function inbox() {
    const notices=Demo.state.notices.filter(n=>n.recipient===ui.user&&n.space===ui.sid);
    return {title:'通知',right:plain('全已读','read-all','','icon-button'),body:notices.length?notices.map(n=>`<button class="surface notice ${n.read?'read':''}" data-act="notice" data-id="${n.id}"><time class="small-copy muted">${!n.read?'<span class="dot"></span>':''}${esc(n.time)}</time><p>${esc(n.text)}</p><span class="small-copy muted">查看详情 ${icon('right')}</span></button>`).join(''):empty('暂时没有新通知','对方记分或处理购买时，会在这里通知你。')};
  }
  function page() {
    const p=ui.page;
    if(p.type==='order')return orderDetail(p.id);
    if(p.type==='agreement')return agreementDetail(p.id);
    if(p.type==='agreement-form')return agreementForm(p.id);
    if(p.type==='item')return itemDetail(p.id);
    if(p.type==='item-form')return itemForm(p.id);
    if(p.type==='event')return eventDetail(p.id);
    if(p.type==='spaces')return spaces();
    if(p.type==='members')return members();
    if(p.type==='inbox')return inbox();
    if(p.type==='pending'){const orders=s().orders.filter(o=>o.status==='pending'&&[o.buyer,o.seller].includes(ui.user));return{title:'待处理',body:orders.length?orders.map(pending).join(''):empty('暂无待处理交易','完成或取消后的交易可以从购买记录查看。',btn('查看购买记录','all-orders','','text'))};}
    if(p.type==='activity')return{title:'空间近况',body:`<div class="surface activity-list">${s().events.length?s().events.map(activity).join(''):empty('暂时没有记录')}</div>`};
    if(p.type==='my')return{title:'我的',body:`<div class="profile"><img class="avatar" src="${media['my-avatar']}" alt=""><div><h2>${esc(Demo.state.users[ui.user].name)}</h2><p class="muted small-copy">每一天，都有小小的收获。</p></div></div><div class="surface menu-list">${plain(`账号信息 ${icon('right')}`,'page','account','menu-row')}${plain(`应用设置 ${icon('right')}`,'page','settings','menu-row')}${plain(`我的空间 ${icon('right')}`,'page','spaces','menu-row')}</div>${btn('退出登录','logout','','text block')}`};
    if(p.type==='account')return{title:'账号信息',body:`<div class="surface info-box">${info('账号名称',esc(Demo.state.users[ui.user].name))}${info('演示账号',`demo-${ui.user}`)}</div><p class="helper">当前使用原型演示身份。正式登录方式在工程方案阶段确定。</p>`};
    if(p.type==='settings')return{title:'应用设置',body:`<div class="surface menu-list">${plain(`外观 <span>${themeNames[Demo.state.users[ui.user].theme]} ${icon('right')}</span>`,'page','appearance','menu-row')}<div class="menu-row">站内通知 <span class="muted">已开启</span></div></div><p class="helper">主题由你自己选择，应用到你参与的所有空间。</p>`};
    if(p.type==='appearance')return{title:'外观',body:`${Object.entries(themeNames).map(([k,n])=>`<button class="theme-option" data-act="theme" data-id="${k}" aria-pressed="${Demo.state.users[ui.user].theme===k}"><img class="theme-art" src="${media[k]}" alt="${n}装饰"><div class="grow"><strong>${n}</strong><div class="swatches">${({apricot:['#F8F4EE','#F0DBCE','#A65A40'],celadon:['#F5F6EF','#E1E8DD','#506D5D'],rose:['#FAF4F2','#EFDFE2','#935D69']})[k].map(c=>`<span style="background:${c}"></span>`).join('')}</div></div><span class="chosen-mark"></span></button>`).join('')}<p class="helper">点选即保存。所有空间沿用你的选择，对方的外观由对方自己决定。</p>`};
    if(p.type==='login')return{title:'演示登录',body:`${empty('选择一个演示账号','账号共用同一份空间数据。')}${Object.entries(Demo.state.users).map(([u,x])=>btn(esc(x.name),'identity',u,'block')).join('<br>')}`};
    return{title:'页面',body:empty('返回后继续操作')};
  }
  function render() {
    if(!me()?.active&&!['spaces','my','account','settings','appearance','login'].includes(ui.page?.type)){ui.page={type:'spaces'};ui.stack=[];}
    const p=ui.page?page():null;
    stage.innerHTML=`${statusBar()}${p?top(p.title,p.right):header()}<div class="network-banner" id="network-banner">${ui.offline?'当前网络不可用，请在演示设置中恢复网络后重试。':''}</div><div class="content ${!p&&ui.tab==='home'?'home-content':''}" id="content">${p?p.body:({home,agreements,shop,records})[ui.tab]()}</div>${p?.footer?`<div class="footer-actions">${p.footer}</div>`:''}${!p?nav():''}<div class="safe-bottom" aria-hidden="true"></div>`;
    if(!p&&ui.tab==='agreements')stage.querySelector('[data-change="member"]').value=ui.member;
    if(!p&&ui.tab==='shop'&&stage.querySelector('[data-change="seller"]'))stage.querySelector('[data-change="seller"]').value=ui.seller;
    if(!p&&ui.tab==='records'){stage.querySelector('[data-change="record-filter"]').value=ui.recordFilter;if(stage.querySelector('[data-change="order-filter"]'))stage.querySelector('[data-change="order-filter"]').value=ui.orderFilter;}
    theme();renderDemo();
  }
  function go(type,id){ui.stack.push({page:ui.page?{...ui.page}:null,tab:ui.tab,scroll:document.getElementById('content')?.scrollTop||0});ui.page={type,id};render();document.getElementById('content').scrollTop=0;}
  function back(){if(ui.modal){closeModal();return;}const prev=ui.stack.pop();ui.page=prev?.page||null;ui.tab=prev?.tab||ui.tab;render();document.getElementById('content').scrollTop=prev?.scroll||0;}
  function tab(id){closeModal();ui.page=null;ui.stack=[];ui.tab=id;render();}
  function ledger(id){ui.recordMode='points';ui.recordFilter=id;tab('records');}
  function modal(title,body,actions='',kind='generic',id=''){
    modalFocus=document.activeElement;ui.modal={kind,id,key:`${kind}-${Date.now()}-${Math.random()}`};
    overlay.innerHTML=`<section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title" tabindex="-1"><div class="handle" aria-hidden="true"></div><div class="sheet-header"><h2 id="sheet-title">${title}</h2>${plain('关闭','close')}</div><div class="sheet-body">${body}<p class="form-error" id="modal-error" role="alert"></p>${actions?`<div class="sheet-actions">${actions}</div>`:''}</div></section>`;
    stage.inert=true;overlay.querySelector('.sheet').focus();
  }
  function closeModal(){if(ui.busy)return;ui.modal=null;overlay.innerHTML='';stage.inert=false;if(modalFocus?.isConnected)modalFocus.focus();}
  function openScore(aid){
    const agreements=s().agreements.filter(a=>a.active&&a.applies.some(u=>s().members[u]?.active));
    if(!agreements.length){modal('先写下一条约定',`<p>约定生效后，就可以按约定给成员记分。</p>`,btn('创建约定','new-agreement-from-sheet','','primary'),'empty');return;}
    const chosen=agreements.find(a=>a.id===aid)||agreements[0];
    modal('记一笔',`<label class="form-field"><span>约定</span><select data-change="score-agreement" id="score-agreement" style="width:100%">${agreements.map(a=>`<option value="${a.id}" ${a.id===chosen.id?'selected':''}>${esc(a.name)}（${a.points>0?'+':''}${a.points} 分）</option>`).join('')}</select></label><label class="form-field"><span>涉及成员</span><select id="score-member" data-change="score-member" style="width:100%"></select></label><div id="score-preview"></div>`,'','score',chosen.id);updateScore(true);
  }
  function updateScore(resetMember=false){
    const a=s().agreements.find(a=>a.id===document.getElementById('score-agreement').value), select=document.getElementById('score-member');
    const choices=a.applies.filter(u=>s().members[u]?.active);if(resetMember){const value=choices.includes(ui.user)?ui.user:choices.length===1?choices[0]:'';select.innerHTML=`<option value="" ${!value?'selected':''} disabled>请选择成员</option>${choices.map(u=>`<option value="${u}" ${u===value?'selected':''}>${esc(nm(u))}${u===ui.user?'（我）':''}</option>`).join('')}`;}
    const u=select.value;document.getElementById('score-preview').innerHTML=`<div class="score-preview">${info('本次记分',delta(a.points))}${u?info('积分余额',`${s().members[u].balance} → ${s().members[u].balance+a.points} 分`):''}</div>${btn(u?`给${esc(nm(u))}${a.points>0?'加':'扣'} ${Math.abs(a.points)} 分`:'选择成员后记分','submit-score','','primary block',!u)}`;
  }
  function openBuy(id){const i=s().items.find(x=>x.id===id);modal('确认购买',`<div class="summary">${photo(i)}<h3>${esc(i.name)}</h3></div>${info('单价',`${i.price} 分 / 份`)}<div class="info-row"><span>数量</span><div class="quantity">${plain(icon('minus'),'quantity','-1','quantity-step" aria-label="减少数量')}<input id="quantity" aria-label="购买数量" type="number" min="1" step="1" value="1" data-change="quantity">${plain(icon('add'),'quantity','1','quantity-step" aria-label="增加数量')}</div></div><div id="purchase-totals"></div>`,'','buy',id);updateBuy();}
  function updateBuy(){const i=s().items.find(x=>x.id===ui.modal.id),input=document.getElementById('quantity'),q=Number(input.value),valid=Demo.integer(input.value)&&Number.isSafeInteger(q*i.price),total=valid?q*i.price:0,balance=me().balance;
    document.getElementById('purchase-totals').innerHTML=`${info('合计',valid?`<strong>${total} 分</strong>`:'—')}${info('积分余额',valid?`${balance} → ${balance-total} 分`:`${balance} 分`)}${!valid?'<p class="form-error">数量请填写正整数。</p>':balance<total?`<p class="form-error">余额不足，还差 ${total-balance} 分。</p><div class="item-actions">${btn('查看积分','sheet-ledger','','text small')}${btn('去记分','sheet-agreements','','text small')}</div>`:''}<p class="sheet-note">购买后立即支付积分，双方都可以处理这笔购买。</p>${btn(valid?`支付 ${total} 分购买`:'请修正数量','submit-buy','','primary block',!valid||balance<total)}`;
  }
  function refund(id){const o=s().orders.find(o=>o.id===id);if(o.status==='cancelled'){toast('这笔购买已取消，积分已退还');render();return;}modal('取消这笔购买？',`<div class="summary">${photo(o)}<h3>${esc(o.name)} × ${o.quantity}</h3></div>${info('退款对象',esc(nm(o.buyer)))}${info('退还积分',`<span class="refund-value">${o.total} 分</span>`)}<p class="sheet-note">整笔取消，已提供部分内容也全额退款。</p>`,`${btn('保留购买','close')}${btn('取消并退款','submit-refund',id,'primary')}`,'refund',id);}
  async function commit(fn,message,after){
    if(ui.busy)return;ui.busy=true;const buttons=[...app.querySelectorAll('button,input,textarea,select')];const disabled=buttons.map(b=>b.disabled);buttons.forEach(b=>b.disabled=true);app.setAttribute('aria-busy','true');
    const clicked=document.activeElement;const label=clicked?.tagName==='BUTTON'?clicked.innerHTML:null;if(label!==null)clicked.textContent='处理中…';
    await new Promise(r=>setTimeout(r,350));
    try{if(ui.offline)throw new Error('网络不可用。请恢复网络后重试，填写内容已保留。');if(ui.failNext){ui.failNext=false;throw new Error('这次提交失败，请重试。填写内容已保留。');}const result=fn();ui.busy=false;closeModal();if(after)after(result);else render();if(message)toast(message);}
    catch(e){const target=document.getElementById('modal-error')||document.querySelector('form .form-error');if(target)target.textContent=e.message;else toast(e.message);}
    finally{ui.busy=false;app.removeAttribute('aria-busy');buttons.forEach((b,i)=>{if(b.isConnected)b.disabled=disabled[i];});if(label!==null&&clicked.isConnected)clicked.innerHTML=label;renderDemo();}
  }
  function renderDemo(){
    const current=s(); const orders=current?.orders||[];
    document.getElementById('demo-panel').innerHTML=`<h1>可点击原型</h1><p>试走双方的积分、购买与退出流程，看看页面和反馈是否顺手。</p><label for="demo-user">当前演示身份</label><select id="demo-user" data-change="identity">${Object.entries(Demo.state.users).map(([u,x])=>`<option value="${u}" ${ui.user===u?'selected':''}>${x.name}${u==='c'?' · 受邀成员':''}</option>`).join('')}</select><label for="demo-scenario">重新开始一个场景</label><select id="demo-scenario" data-change="scenario"><option value="">选择场景…</option><option value="normal">两份早餐待完成 · 阿禾 10 分</option><option value="negative">负余额 · 阿禾 −5 分</option><option value="empty">空白空间 · 从 0 开始</option><option value="long">长昵称与长商品名称</option></select><label for="demo-font">阅读字号</label><select id="demo-font" data-change="zoom"><option value="1" ${ui.zoom===1?'selected':''}>标准</option><option value="1.3" ${ui.zoom===1.3?'selected':''}>放大 130%</option><option value="1.6" ${ui.zoom===1.6?'selected':''}>放大 160%</option></select><label class="demo-check"><input type="checkbox" data-change="offline" ${ui.offline?'checked':''}>模拟网络不可用</label><label class="demo-check"><input type="checkbox" data-change="fail" ${ui.failNext?'checked':''}>下一次提交失败</label><div class="demo-state"><strong>${esc(current?.name||'尚未选择空间')}</strong>${current?Object.entries(current.members).map(([u,m])=>`<p>${esc(m.nick)}：${m.balance} 分${m.active?'':' · 已退出'}</p>`).join(''):''}<p>${orders.filter(o=>o.status==='pending').length} 笔待完成 · ${orders.filter(o=>o.status==='completed').length} 笔已完成 · ${orders.filter(o=>o.status==='cancelled').length} 笔已取消</p></div><details><summary>跟着流程试一遍</summary><div class="guide"><button data-act="guide" data-id="0">1. 回到阿禾，给自己记一笔</button><button data-act="guide" data-id="1">2. 去小卖部，购买两份早餐</button><button data-act="guide" data-id="2">3. 切换小满，完成或取消购买</button><button data-act="guide" data-id="3">试试：成员退出与重新加入</button><button data-act="guide" data-id="4">试试：邀请小桥，等待全部同意</button></div></details><p class="quiet">演示数据保存在当前页面内存中，刷新或重置后恢复。正式应用使用 Flutter + Go。</p>`;
  }
  function identity(u){if(ui.busy)return;closeModal();ui.user=u;ui.page=null;ui.stack=[];ui.tab='home';ui.recordFilter='me';render();}
  function openLeave(){const orders=s().orders.filter(o=>o.status==='pending'&&[o.buyer,o.seller].includes(ui.user));const toMe=orders.filter(o=>o.buyer===ui.user).reduce((n,o)=>n+o.total,0),toOthers=orders.filter(o=>o.buyer!==ui.user).reduce((n,o)=>n+o.total,0);modal('退出这个空间？',`<p>余额与历史会保留，你可以随时重新加入。</p><p class="sheet-note">与你有关的 ${orders.length} 笔待完成购买将自动整笔取消。</p>${info('退还给我',`${toMe} 分`)}${info('退还其他买方',`${toOthers} 分`)}${orders.filter(o=>o.buyer!==ui.user).map(o=>info(`${esc(nm(o.buyer))} · ${esc(o.name)} × ${o.quantity}`,`${o.total} 分`)).join('')}<p class="sheet-note">已完成的购买保留当前状态。</p>`,btn('继续参与','close')+btn('退出空间','submit-leave','','primary'),'leave');}
  const actions={
    page:id=>go(id),tab,back,close:closeModal,ledger,
    order:id=>go('order',id),agreement:id=>go('agreement',id),item:id=>go('item',id),event:id=>go('event',id),
    'agreement-form':id=>go('agreement-form',id),'item-form':id=>go('item-form',id),
    score:openScore,buy:openBuy,refund,
    complete:id=>commit(()=>Demo.complete(ui.sid,ui.user,id),'已确认整笔完成'),
    'submit-refund':id=>commit(()=>Demo.cancel(ui.sid,ui.user,id),'已整笔取消，积分已退还'),
    'toggle-agreement':id=>commit(()=>Demo.toggleAgreement(ui.sid,ui.user,id),'约定状态已更新'),
    'toggle-item':id=>commit(()=>Demo.toggleItem(ui.sid,ui.user,id),'商品状态已更新'),
    'submit-score':()=>{const key=ui.modal.key,aid=document.getElementById('score-agreement').value,target=document.getElementById('score-member').value;commit(()=>Demo.record(ui.sid,ui.user,aid,target,key),'记分已生效');},
    'submit-buy':()=>{const key=ui.modal.key,iid=ui.modal.id,q=document.getElementById('quantity').value;commit(()=>Demo.buy(ui.sid,ui.user,iid,q,key),'购买成功',o=>go('order',o.id));},
    quantity:amount=>{const input=document.getElementById('quantity');input.value=Math.max(1,(Number(input.value)||0)+Number(amount));updateBuy();},
    'agreement-filter':id=>{ui.agreementActive=id==='active';render();},
    'shop-mode':id=>{ui.shop=id;render();},'record-mode':id=>{ui.recordMode=id;render();},
    'all-orders':()=>{ui.recordMode='orders';ui.recordFilter='me';ui.orderFilter='all';tab('records');},
    'sheet-ledger':()=>{closeModal();ledger(ui.user);},'sheet-agreements':()=>{closeModal();tab('agreements');},
    'new-agreement-from-sheet':()=>{closeModal();go('agreement-form');},
    'revoke-confirm':id=>{const e=s().events.find(x=>x.id===id);modal('撤销这次记分？',`${info('涉及成员',esc(nm(e.target)))}${info('原记分',delta(e.delta))}${info('本次回退',delta(-e.delta))}<p class="sheet-note">按原记分回退，原记录和撤销经过都会保留。</p>`,btn('保留记录','close')+btn('撤销记分','submit-revoke',id,'primary'),'revoke',id);},
    'submit-revoke':id=>commit(()=>Demo.revoke(ui.sid,ui.user,id),'已撤销，积分已回退'),
    theme:id=>{Demo.state.users[ui.user].theme=id;theme();toast('外观已保存');},
    'space':id=>{ui.sid=id;ui.page=null;ui.stack=[];ui.tab='home';ui.member='all';ui.seller='all';ui.recordFilter='me';render();},
    'space-manage':id=>{ui.sid=id;ui.page={type:'members'};ui.stack=[{page:{type:'spaces'},tab:'home'}];render();},
    restore:id=>commit(()=>Demo.restore(id,ui.user),'已恢复参与',()=>actions.space(id)),
    'new-space':()=>modal('创建空间','<label class="form-field"><span>空间名称</span><input type="text" id="space-name" maxlength="60" placeholder="给共同生活起一个名字"></label>',btn('创建空间','submit-space','','primary'),'new-space'),
    'submit-space':()=>{const n=document.getElementById('space-name').value;commit(()=>Demo.createSpace(ui.user,n),'空间已创建',x=>actions.space(x.id));},
    'invite-new':()=>{const choices=Object.keys(Demo.state.users).filter(u=>!s().members[u]);modal('邀请成员',choices.length?`<label class="form-field"><span>邀请对象</span><select id="invite-user" style="width:100%">${choices.map(u=>`<option value="${u}">${esc(Demo.state.users[u].name)}</option>`).join('')}</select></label><p class="sheet-note">对方接受后，需要当前成员全部同意。发起邀请视为你已同意。</p>`:'<p>演示账号都已参与过这个空间，已退出的成员可以直接重新加入。</p>',choices.length?btn('创建邀请','submit-invite','','primary'):'','invite');},
    'submit-invite':()=>{const u=document.getElementById('invite-user').value;commit(()=>Demo.invite(ui.sid,ui.user,u),'邀请已创建，可切换受邀账号接受');},
    'invite-answer':id=>{const [sid,iid]=id.split('|');commit(()=>Demo.answerInvite(sid,ui.user,iid),'加入进度已更新');},
    nickname:()=>modal('我的空间昵称',`<label class="form-field"><span>昵称</span><input id="nickname" type="text" maxlength="40" value="${esc(nm(ui.user))}"></label>`,btn('保存昵称','submit-nickname','','primary'),'nickname'),
    'submit-nickname':()=>{const n=document.getElementById('nickname').value;commit(()=>Demo.nickname(ui.sid,ui.user,n),'昵称已更新');},
    'leave-confirm':openLeave,'submit-leave':()=>commit(()=>Demo.leave(ui.sid,ui.user),'已退出，待完成购买已自动处理',()=>{ui.page={type:'spaces'};ui.stack=[];render();}),
    'read-all':()=>{Demo.state.notices.filter(n=>n.recipient===ui.user&&n.space===ui.sid).forEach(n=>n.read=true);render();},
    notice:id=>{const n=Demo.state.notices.find(n=>n.id===id);n.read=true;if(n.invite){go('spaces');return;}if(!s()?.members[ui.user]?.active){go('spaces');return;}go(n.order?'order':n.event?'event':'activity',n.order||n.event);},
    'remove-photo':()=>{ui.photo='';const img=document.getElementById('photo-preview');img.hidden=true;img.removeAttribute('src');},
    logout:()=>{ui.page={type:'login'};ui.stack=[];render();},identity,
    guide:id=>{document.body.classList.remove('demo-open');document.getElementById('demo-toggle').setAttribute('aria-expanded','false');if(id==='0'){identity('a');actions.space('home');openScore('walk');}if(id==='1'){identity('a');actions.space('home');ui.shop='browse';tab('shop');}if(id==='2'){identity('b');actions.space('home');}if(id==='3'){go('members');}if(id==='4'){identity('a');actions.space('home');go('members');actions['invite-new']();}},
  };
  document.addEventListener('click',e=>{const b=e.target.closest('[data-act]');if(!b||ui.busy||b.disabled)return;const fn=actions[b.dataset.act];if(fn){e.preventDefault();fn(b.dataset.id);}});
  overlay.addEventListener('click',e=>{if(e.target===overlay)closeModal();});
  document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(ui.modal)closeModal();else if(document.body.classList.contains('demo-open'))document.getElementById('demo-toggle').click();return;}if(e.key==='Tab'&&ui.modal){const focusable=[...overlay.querySelectorAll('button:not(:disabled),input:not(:disabled),select:not(:disabled),textarea:not(:disabled),[tabindex="0"]')];if(!focusable.length)return;const first=focusable[0],last=focusable.at(-1);if(e.shiftKey&&(document.activeElement===first||document.activeElement.classList.contains('sheet'))){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}});
  document.addEventListener('change',async e=>{const kind=e.target.dataset.change;if(!kind)return;if(ui.busy){renderDemo();return;}const v=e.target.value;
    if(kind==='identity')identity(v);
    if(kind==='scenario'){Demo.reset(v||'normal');ui.sid='home';ui.user='a';ui.offline=false;ui.failNext=false;ui.modal=null;overlay.innerHTML='';stage.inert=false;ui.page=null;ui.stack=[];ui.tab='home';ui.member='all';ui.seller='all';render();}
    if(kind==='zoom'){ui.zoom=Number(v);theme();}
    if(kind==='offline'){ui.offline=e.target.checked;document.getElementById('network-banner').textContent=ui.offline?'当前网络不可用，请在演示设置中恢复网络后重试。':'';}
    if(kind==='fail')ui.failNext=e.target.checked;
    if(kind==='member'){ui.member=v;render();}if(kind==='seller'){ui.seller=v;render();}if(kind==='record-filter'){ui.recordFilter=v;render();}if(kind==='order-filter'){ui.orderFilter=v;render();}
    if(kind==='score-agreement')updateScore(true);if(kind==='score-member')updateScore();
    if(kind==='photo'){const file=e.target.files[0];if(!file)return;const error=document.querySelector('#item-form .form-error');if(!file.type.startsWith('image/')||file.size>5*1024*1024){error.textContent='请选择 5 MB 以内的图片。';return;}const reader=new FileReader();reader.onload=()=>{ui.photo=reader.result;const img=document.getElementById('photo-preview');if(img){img.src=ui.photo;img.hidden=false;error.textContent='';}};reader.readAsDataURL(file);}
  });
  document.addEventListener('input',e=>{if(e.target.dataset.change==='quantity')updateBuy();});
  document.addEventListener('submit',e=>{const f=e.target;if(!f.dataset.submit)return;e.preventDefault();if(ui.busy)return;const d=new FormData(f),id=f.dataset.id;
    if(f.dataset.submit==='agreement'){const old=s().agreements.find(a=>a.id===id);const applies=[...d.getAll('applies'),...(old?.applies.filter(u=>!s().members[u]?.active)||[])];const values={name:d.get('name'),description:d.get('description'),points:Number(d.get('points'))*Number(d.get('sign')),applies};commit(()=>Demo.saveAgreement(ui.sid,ui.user,values,id),'约定已保存',()=>{back();});}
    if(f.dataset.submit==='item'){const values={name:d.get('name'),description:d.get('description'),price:d.get('price'),photo:ui.photo};commit(()=>Demo.saveItem(ui.sid,ui.user,values,id),'商品已保存',()=>{ui.shop='mine';tab('shop');});}
  });
  document.getElementById('demo-toggle').addEventListener('click',()=>{const open=document.body.classList.toggle('demo-open');document.getElementById('demo-toggle').setAttribute('aria-expanded',String(open));});
  if(new URLSearchParams(location.search).has('comp'))document.documentElement.classList.add('comp');
  render();
  // Read-only inspection seam for reviewing the prototype; no remote services.
  window.prototypeView=()=>({user:ui.user,space:ui.sid,tab:ui.tab,page:ui.page,modal:ui.modal?.kind,theme:app.dataset.theme,busy:ui.busy});
})();
