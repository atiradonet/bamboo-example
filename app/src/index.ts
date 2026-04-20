import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import userRoutes from "./routes/users";

const app = express();
const PORT = process.env.PORT || 3000;

// CORS misconfiguration — allows all origins (Snyk Code: CorsAllowAll)
app.use(cors({ origin: "*" }));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// No helmet or security headers — deliberate omission

app.get("/", (req, res) => {
  res.json({
    service: "bamboo-example-app",
    version: "1.0.0",
    endpoints: ["/users", "/health"],
  });
});

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.use("/users", userRoutes);

// Verbose error handler — exposes stack traces (Snyk Code: InformationExposure)
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({
    error: err.message,
    stack: err.stack,
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
