/**
 * 唯品会商品搜索 —— 读登录态搜索结果页的 DOM 卡片。
 *
 * 2026-11-22 实测：
 *  - category.vip.com/suggest.php?keyword=<kw> 未登录会 302 到 passport.vip.com/login；
 *    登录后正常渲染，单页 50 个 .c-goods-item，分页参数 page=1..N。
 *  - 卡片结构稳定：data-product-id、.c-goods-item__name、
 *    .c-goods-item__sale-price + .c-goods-item__sale-price-decimal（整数和小数分两个节点）、
 *    .c-goods-item__market-price、.c-goods-item__discount。
 *  - 价格单位元，折扣是「X折」文本。
 *
 * 已知边界：只取首屏 50 条；详情页/评论不在本命令范围。
 */
import { cli, Strategy } from '@jackwener/opencli/registry';
import { ArgumentError, AuthRequiredError, EmptyResultError } from '@jackwener/opencli/errors';

const SEARCH_URL = 'https://category.vip.com/suggest.php';
const PAGE_SIZE = 50;

function requireQuery(value) {
  const query = String(value ?? '').trim();
  if (!query) throw new ArgumentError('query 不能为空', 'opencli vipshop search 连衣裙');
  return query;
}

function clampInt(raw, fallback, min, max) {
  const n = Number(raw);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(Math.floor(n), max));
}

cli({
  site: 'vipshop',
  name: 'search',
  access: 'read',
  description: '唯品会商品搜索（需登录态；返回标题、特卖价、原价、折扣）',
  domain: 'category.vip.com',
  strategy: Strategy.COOKIE,
  args: [
    { name: 'query', positional: true, required: true, help: '搜索关键词' },
    { name: 'limit', type: 'int', default: 20, help: `返回条数 (1-${PAGE_SIZE}，首屏上限)` },
  ],
  columns: ['rank', 'title', 'price', 'marketPrice', 'discount', 'productId', 'url'],
  func: async (page, kwargs) => {
    const query = requireQuery(kwargs.query);
    const limit = clampInt(kwargs.limit, 20, 1, PAGE_SIZE);

    await page.goto(`${SEARCH_URL}?keyword=${encodeURIComponent(query)}`);

    const state = await page.evaluate(`(async () => {
      for (let i = 0; i < 40; i++) {
        if (/passport\\.vip\\.com\\/login/.test(location.href)) return { login: true, items: [] };
        if (document.querySelector('.c-goods-item')) break;
        await new Promise(r => setTimeout(r, 500));
      }
      if (/passport\\.vip\\.com\\/login/.test(location.href)) return { login: true, items: [] };

      const cards = [...document.querySelectorAll('.c-goods-item')];
      const num = s => parseFloat(String(s || '').replace(/[^0-9.]/g, '')) || 0;
      const txt = (c, s) => { const e = c.querySelector(s); return e ? e.innerText.trim() : ''; };

      return {
        login: false,
        items: cards.map(c => {
          const a = c.querySelector('a');
          return {
            id: c.getAttribute('data-product-id') || '',
            title: txt(c, '.c-goods-item__name'),
            price: num(txt(c, '.c-goods-item__sale-price') + txt(c, '.c-goods-item__sale-price-decimal')),
            market: num(txt(c, '.c-goods-item__market-price')),
            discount: txt(c, '.c-goods-item__discount'),
            href: a ? a.getAttribute('href') : '',
          };
        }),
      };
    })()`);

    if (state && state.login) {
      throw new AuthRequiredError(
        'category.vip.com',
        '唯品会搜索需要登录态',
        '在这个浏览器打开 https://passport.vip.com/login 登录一次，然后重跑',
      );
    }

    const items = (state && state.items) || [];
    if (!items.length) {
      throw new EmptyResultError(`vipshop search "${query}"`, '没搜到结果，或页面结构已变');
    }

    return items.slice(0, limit).map((it, i) => ({
      rank: i + 1,
      title: it.title,
      price: it.price ? it.price.toFixed(2) : '',
      marketPrice: it.market ? it.market.toFixed(2) : '',
      discount: it.discount,
      productId: it.id,
      url: it.href ? (it.href.startsWith('//') ? `https:${it.href}` : it.href) : '',
    }));
  },
});

export const __test__ = { clampInt, requireQuery };
