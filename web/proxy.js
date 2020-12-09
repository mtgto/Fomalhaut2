const { createProxyMiddleware } = require("http-proxy-middleware");
const Bundler = require("parcel-bundler");
const express = require("express");

const bundler = new Bundler("./src/index.html");

const app = express();

app.use(
  ["/api", "/images"],
  createProxyMiddleware({
    target: "http://localhost:8080",
  })
);

app.use(bundler.middleware());

app.listen(Number(process.env.PORT || 1234));
