const connectionString = process.env.NEON_DATABASE_URL;

if (connectionString) {
  process.env.POSTGRES_URL = connectionString;
}

const { sql } = require('@vercel/postgres');

module.exports = async (req, res) => {
  const date = (req.query?.date || '').trim();
  const requestId = req.headers['x-vercel-id'] || req.headers['x-request-id'];

  if (!date) {
    res.statusCode = 400;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'missing date' }));
    return;
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    res.statusCode = 400;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'invalid date format' }));
    return;
  }

  if (!process.env.POSTGRES_URL) {
    res.statusCode = 500;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'database not configured', requestId }));
    return;
  }

  try {
    const { rows } = await sql`
      select lat, lng, ts
      from public.location_points
      where ts >= ${date}::date
        and ts < (${date}::date + interval '1 day')
      order by ts asc
    `;

    res.statusCode = 200;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ date, points: rows }));
  } catch (error) {
    console.error('locations query failed', {
      requestId,
      date,
      message: error?.message,
      code: error?.code,
      detail: error?.detail,
      hint: error?.hint
    });
    res.statusCode = 500;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'query failed', requestId }));
  }
};
