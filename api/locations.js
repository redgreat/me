const { sql } = require('@vercel/postgres');

module.exports = async (req, res) => {
  const date = (req.query?.date || '').trim();

  if (!date) {
    res.statusCode = 400;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'missing date' }));
    return;
  }

  try {
    const { rows } = await sql`
      select lat, lng, ts
      from location_points
      where ts >= ${date}::date
        and ts < (${date}::date + interval '1 day')
      order by ts asc
    `;

    res.statusCode = 200;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ date, points: rows }));
  } catch (error) {
    res.statusCode = 500;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'query failed' }));
  }
};
