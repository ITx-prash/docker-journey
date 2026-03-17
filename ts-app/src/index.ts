import http from "http";
import Redis from "ioredis";
import { Client } from "pg";
import app from "./app/server";

async function init() {
  try {
    // Redis Connection
    console.log(`Connecting Redis...`);
    const redis = new Redis("redis://localhost:6379", { lazyConnect: true });
    await redis.connect();
    console.log(`Redis Connection Success...`);

    // Postgresql Connection
    console.log(`Connecting Postgres...`);
    const client = new Client({
      host: "localhost",
      port: 5432,
      database: "postgres",
      user: "postgres",
      password: "1234",
    });
    await client.connect();

    console.log(`Postgres Connection Success...`);
    //http server stuff
    const PORT = process.env.PORT ? +process.env.PORT : 8000;
    const server = http.createServer(app);
    server.listen(PORT, () =>
      console.log(`Http server is listening on PORT ${PORT}`),
    );
  } catch (err) {
    console.log(`Error Starting Server`, err);
  }
}

init();
