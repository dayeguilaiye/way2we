/* 可点击原型 · 内存演示数据。刷新恢复；正式实现使用 Go 事务与权限校验。 */
window.Demo = (() => {
  let state, counter = 100;
  const now = () => new Date().toLocaleString('zh-CN', { hour12: false });
  const id = () => `d${++counter}`;
  const clone = v => structuredClone(v);
  const fail = message => { throw new Error(message); };
  const integer = v => Number.isSafeInteger(Number(v)) && Number(v) > 0;
  function reset(kind = 'normal') {
    counter = 100;
    state = {
      users: { a: { name: '阿禾', avatar: 'avatar-a', theme: 'apricot' }, b: { name: '小满', avatar: 'avatar-b', theme: 'apricot' }, c: { name: '小桥', avatar: 'my-avatar', theme: 'celadon' } },
      spaces: {}, notices: [], requests: {},
    };
    const make = (name, members) => ({ id: id(), name, members: Object.fromEntries(members.map(u => [u, { active: true, balance: 0, nick: state.users[u].name }])), agreements: [], items: [], orders: [], events: [], invites: [] });
    const s = make('一起的小日子', ['a', 'b']); s.id = 'home'; state.spaces.home = s;
    const other = make('周末的小计划', ['a', 'b']); other.id = 'weekend'; state.spaces.weekend = other;
    s.agreements = [
      { id: 'walk', name: '散步 30 分钟', description: '一起出门走走，给忙碌的一天留一点空白。', points: 10, applies: ['a', 'b'], active: true },
      { id: 'shoes', name: '鞋子忘了放回原位', description: '进门后，把鞋子放整齐。', points: -5, applies: ['a', 'b'], active: true },
    ];
    s.items = [
      { id: 'breakfast', owner: 'b', name: '准备一份早餐', description: '一份热乎乎的早餐，搭配你喜欢的饮品。前一天告诉我就好。', price: 10, photo: 'assets/breakfast.png', listed: true },
      { id: 'movie', owner: 'b', name: '一起看一场电影', description: '电影由你选，我负责零食和陪伴。', price: 20, photo: 'assets/movie.png', listed: true },
    ];
    if (kind !== 'empty') {
      for (let n = 0; n < 3; n++) record('home', 'a', 'walk', 'a', `seed-score-${n}`);
      buy('home', 'a', 'breakfast', 2, 'seed-order');
      s.events.forEach((e, i) => e.time = i === 0 ? '今天 08:40' : '今天 08:30');
      s.orders[0].history[0].time = '今天 08:40';
    } else { s.agreements = []; s.items = []; }
    if (kind === 'negative') { record('home', 'a', 'shoes', 'a'); record('home', 'a', 'shoes', 'a'); record('home', 'a', 'shoes', 'a'); }
    if (kind === 'long') { s.name = '属于我们的那些平凡又值得记录的小日子'; s.members.a.nick = '认真照顾每一天的阿禾'; s.items[0].name = '周末一起慢慢享用的一份丰盛早餐和热饮'; s.orders[0].name = s.items[0].name; }
    state.notices = [];
    return state;
  }
  const space = sid => state.spaces[sid] || fail('找不到这个空间');
  const active = (s, u) => s.members[u]?.active || fail('请先恢复参与这个空间');
  const name = (s, u) => s.members[u]?.nick || state.users[u]?.name || '成员';
  const valid = (value, label) => integer(value) ? Number(value) : fail(`${label}请填写正整数`);
  function event(s, actor, text, extra = {}) {
    const e = { id: id(), actor, text, time: now(), ...extra }; s.events.unshift(e); return e;
  }
  function notify(s, actor, text, extra = {}) {
    Object.entries(s.members).forEach(([recipient, m]) => { if (recipient !== actor && m.active) state.notices.unshift({ id: id(), recipient, space: s.id, text, read: false, time: now(), ...extra }); });
  }
  function once(key, fn) { if (key && key in state.requests) return state.requests[key]; const result = fn(); if (key) state.requests[key] = result; return result; }
  function record(sid, actor, aid, target, key) {
    return once(key, () => {
      const s = space(sid); active(s, actor); active(s, target);
      const a = s.agreements.find(a => a.id === aid); if (!a?.active) fail('这条约定已停用，请选择生效中的约定');
      if (!a.applies.includes(target)) fail('这位成员不在约定的适用范围内');
      if (!Number.isSafeInteger(s.members[target].balance + a.points)) fail('积分数值超出范围');
      s.members[target].balance += a.points;
      const e = event(s, actor, `${name(s, actor)}为${actor === target ? '自己' : name(s, target)}记录「${a.name}」`, { type: 'score', target, delta: a.points, agreement: aid, originalName: a.name, revoked: false });
      notify(s, actor, e.text, { event: e.id }); return e;
    });
  }
  function revoke(sid, actor, eid) {
    const s = space(sid); active(s, actor); const e = s.events.find(e => e.id === eid && e.type === 'score');
    if (!e) fail('找不到记分记录'); if (e.revoked) return e;
    e.revoked = true; e.revokedBy = actor; e.revokedAt = now(); s.members[e.target].balance -= e.delta;
    const r = event(s, actor, `${name(s, actor)}撤销了「${e.originalName}」的记分`, { type: 'revoke', target: e.target, delta: -e.delta, original: e.id });
    notify(s, actor, r.text, { event: e.id }); return e;
  }
  function saveAgreement(sid, actor, values, aid) {
    const s = space(sid); active(s, actor);
    const n = values.name.trim(); if (!n) fail('请填写约定名称');
    const points = valid(Math.abs(Number(values.points)), '分值') * (Number(values.points) < 0 ? -1 : 1);
    const applies = values.applies.filter(u => s.members[u]); if (!applies.length) fail('请至少选择一位适用成员');
    let a = s.agreements.find(a => a.id === aid); const before = a ? clone(a) : null;
    if (!a) { a = { id: id(), active: true }; s.agreements.unshift(a); }
    Object.assign(a, { name: n, description: values.description.trim(), points, applies });
    const e = event(s, actor, `${name(s, actor)}${before ? '修改' : '创建'}了约定「${n}」`, { type: 'agreement', agreement: a.id, before, after: clone(a) }); notify(s, actor, e.text); return a;
  }
  function toggleAgreement(sid, actor, aid) {
    const s = space(sid); active(s, actor); const a = s.agreements.find(a => a.id === aid); if (!a) fail('找不到约定');
    const before = clone(a); a.active = !a.active; event(s, actor, `${name(s, actor)}${a.active ? '启用' : '停用'}了约定「${a.name}」`, { type: 'agreement', agreement: aid, before, after: clone(a) });
  }
  function saveItem(sid, actor, values, iid) {
    const s = space(sid); active(s, actor); let item = s.items.find(i => i.id === iid);
    if (item && item.owner !== actor) fail('只有店主可以修改商品');
    const n = values.name.trim(); if (!n) fail('请填写商品或服务名称'); const price = valid(values.price, '单价');
    if (!item) { item = { id: id(), owner: actor, listed: true }; s.items.unshift(item); }
    const before = clone(item); Object.assign(item, { name: n, description: values.description.trim(), price, photo: values.photo || '' });
    event(s, actor, `${name(s, actor)}${iid ? '修改' : '上架'}了「${n}」`, { type: 'item', item: item.id, before, after: clone(item) }); return item;
  }
  function toggleItem(sid, actor, iid) {
    const s = space(sid); active(s, actor); const item = s.items.find(i => i.id === iid); if (!item || item.owner !== actor) fail('只有店主可以修改商品');
    item.listed = !item.listed; event(s, actor, `${name(s, actor)}${item.listed ? '上架' : '下架'}了「${item.name}」`, { type: 'item', item: iid });
  }
  function buy(sid, actor, iid, quantity, key) {
    return once(key, () => {
      const s = space(sid); active(s, actor); const item = s.items.find(i => i.id === iid);
      if (!item?.listed || !s.members[item.owner]?.active) fail('这件商品暂时无法购买');
      if (item.owner === actor) fail('请选择其他成员的小卖部');
      const qty = valid(quantity, '数量'), total = qty * item.price;
      if (!Number.isSafeInteger(total)) fail('数量过大，请减少购买数量');
      if (s.members[actor].balance < total) fail(`余额不足，还差 ${total - s.members[actor].balance} 分`);
      const o = { id: id(), buyer: actor, seller: item.owner, item: iid, name: item.name, description: item.description, photo: item.photo, price: item.price, quantity: qty, total, status: 'pending', history: [{ actor, action: '支付积分，购买成立', time: now() }] };
      s.members[actor].balance -= total; s.orders.unshift(o);
      event(s, actor, `${name(s, actor)}购买${name(s, item.owner)}的${item.name.replace('准备一份', '')} × ${qty}`, { type: 'purchase', target: actor, delta: -total, order: o.id });
      notify(s, actor, `${name(s, actor)}购买了「${item.name}」× ${qty}`, { order: o.id }); return o;
    });
  }
  function order(s, oid) { return s.orders.find(o => o.id === oid) || fail('找不到这笔购买'); }
  function complete(sid, actor, oid) {
    const s = space(sid); active(s, actor); const o = order(s, oid); if (![o.buyer, o.seller].includes(actor)) fail('由买方或卖方确认');
    if (o.status === 'completed') return o; if (o.status !== 'pending') fail('这笔购买已经取消');
    o.status = 'completed'; o.history.push({ actor, action: '确认整笔完成', time: now() }); event(s, actor, `${name(s, actor)}确认「${o.name}」× ${o.quantity} 已完成`, { type: 'complete', order: oid }); notify(s, actor, `「${o.name}」已确认完成`, { order: oid }); return o;
  }
  function cancel(sid, actor, oid, auto = false) {
    const s = space(sid); if (!auto) active(s, actor); const o = order(s, oid); if (![o.buyer, o.seller].includes(actor)) fail('由买方或卖方取消');
    if (o.status === 'cancelled') return o;
    o.status = 'cancelled'; s.members[o.buyer].balance += o.total;
    o.history.push({ actor, action: auto ? '退出空间，自动整笔取消并退款' : '整笔取消并退款', time: now() });
    const e = event(s, actor, `${auto ? name(s, actor) + '退出空间，' : ''}「${o.name}」整笔取消，已退还 ${o.total} 分`, { type: 'refund', target: o.buyer, delta: o.total, order: oid, auto }); notify(s, actor, e.text, { order: oid }); return o;
  }
  function leave(sid, actor) {
    const s = space(sid); active(s, actor);
    s.orders.filter(o => o.status === 'pending' && [o.buyer, o.seller].includes(actor)).forEach(o => cancel(sid, actor, o.id, true));
    s.members[actor].active = false; event(s, actor, `${name(s, actor)}退出了空间`, { type: 'membership' }); resolveInvites(s); return s;
  }
  function restore(sid, actor) {
    const s = space(sid); if (!s.members[actor]) fail('请先接受空间邀请'); if (s.members[actor].active) return s;
    s.members[actor].active = true; event(s, actor, `${name(s, actor)}恢复参与空间`, { type: 'membership' }); resolveInvites(s); return s;
  }
  function createSpace(actor, title) {
    if (!title.trim()) fail('请填写空间名称'); const sid = id(); state.spaces[sid] = { id: sid, name: title.trim(), members: { [actor]: { active: true, balance: 0, nick: state.users[actor].name } }, agreements: [], items: [], orders: [], events: [], invites: [] }; return state.spaces[sid];
  }
  function invite(sid, actor, target) {
    const s = space(sid); active(s, actor); if (!state.users[target]) fail('请选择邀请对象');
    if (s.members[target]) fail('这位成员可以直接恢复参与');
    const existing = s.invites.find(i => i.target === target && i.status === 'waiting'); if (existing) return existing;
    const i = { id: id(), target, actor, accepted: false, approvals: [actor], status: 'waiting' }; s.invites.unshift(i);
    state.notices.unshift({ id: id(), recipient: target, space: sid, text: `${name(s, actor)}邀请你加入「${s.name}」`, read: false, time: now(), invite: i.id }); return i;
  }
  function resolveInvites(s) {
    s.invites.filter(i => i.status === 'waiting' && i.accepted).forEach(i => {
      const currentMembers = Object.entries(s.members).filter(([, m]) => m.active);
      if (currentMembers.length > 0 && currentMembers.every(([u]) => i.approvals.includes(u))) {
        s.members[i.target] = { active: true, balance: 0, nick: state.users[i.target].name }; i.status = 'joined';
        const e = event(s, i.target, `${name(s, i.target)}加入了空间`, { type: 'membership' }); notify(s, i.target, e.text);
      }
    });
  }
  function answerInvite(sid, actor, iid) {
    const s = space(sid); const i = s.invites.find(i => i.id === iid); if (!i || i.status !== 'waiting') return;
    if (actor === i.target) i.accepted = true; else { active(s, actor); if (!i.approvals.includes(actor)) i.approvals.push(actor); }
    resolveInvites(s); return i;
  }
  function nickname(sid, actor, nick) { const s = space(sid); active(s, actor); if (!nick.trim()) fail('请填写昵称'); const old = name(s, actor); s.members[actor].nick = nick.trim(); event(s, actor, `${old}把昵称改为${nick.trim()}`, { type: 'membership' }); }
  reset();
  return { get state() { return state; }, reset, space, name, integer, record, revoke, saveAgreement, toggleAgreement, saveItem, toggleItem, buy, complete, cancel, leave, restore, createSpace, invite, answerInvite, nickname };
})();
