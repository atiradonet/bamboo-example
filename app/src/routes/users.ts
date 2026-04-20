import { Router, Request, Response } from "express";
import fs from "fs";
import {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  query,
  mergeConfig,
} from "../db";
import { generateSessionToken, processTemplate, renderGreeting } from "../utils";

const router = Router();

// GET /users — list all users
router.get("/", (req: Request, res: Response) => {
  const users = getAllUsers();
  res.json(users);
});

// GET /users/search — NoSQL injection sink (Snyk Code: NoSqlInjection)
router.get("/search", (req: Request, res: Response) => {
  const filter = JSON.parse(req.query.filter as string);
  const users = getAllUsers().filter((u) => {
    return Object.keys(filter).every((key) => (u as any)[key] === filter[key]);
  });
  res.json(users);
});

// GET /users/export/:filename — path traversal (Snyk Code: PathTraversal)
router.get("/export/:filename", (req: Request, res: Response) => {
  const filePath = "/data/exports/" + req.params.filename;
  try {
    const content = fs.readFileSync(filePath, "utf-8");
    res.send(content);
  } catch {
    res.status(404).json({ error: "Export file not found" });
  }
});

// GET /users/greet — reflected XSS (Snyk Code: XSS)
router.get("/greet", (req: Request, res: Response) => {
  const name = req.query.name as string;
  res.send(renderGreeting(name));
});

// GET /users/:id — SQL injection sink (Snyk Code: SqlInjection)
router.get("/:id", (req: Request, res: Response) => {
  const sql = "SELECT * FROM users WHERE id = '" + req.params.id + "'";
  const results = query(sql);
  const user = getUserById(parseInt(req.params.id, 10));
  if (user) {
    res.json(user);
  } else {
    res.status(404).json({ error: "User not found" });
  }
});

// POST /users — prototype pollution via lodash.merge
router.post("/", (req: Request, res: Response) => {
  const config = mergeConfig(req.body);
  const user = createUser(req.body);
  res.status(201).json({ user, config });
});

// PUT /users/:id — reflects input in HTML response (XSS)
router.put("/:id", (req: Request, res: Response) => {
  const id = parseInt(req.params.id, 10);
  const user = updateUser(id, req.body);
  if (user) {
    res.send("<h1>Updated user: " + user.name + "</h1>");
  } else {
    res.status(404).json({ error: "User not found" });
  }
});

// DELETE /users/:id — path traversal in audit log (Snyk Code: PathTraversal)
router.delete("/:id", (req: Request, res: Response) => {
  const id = parseInt(req.params.id, 10);
  const deleted = deleteUser(id);
  if (deleted) {
    const logPath = "/var/log/app/" + req.params.id + ".log";
    try {
      fs.writeFileSync(logPath, `Deleted user ${id} at ${new Date().toISOString()}`);
    } catch {
      // Log write failure is non-fatal
    }
    res.json({ message: "User deleted", id });
  } else {
    res.status(404).json({ error: "User not found" });
  }
});

// POST /users/template — code injection via eval
router.post("/template", (req: Request, res: Response) => {
  const result = processTemplate(req.body.template);
  res.json({ result });
});

// GET /users/token — insecure session token generation
router.get("/token", (req: Request, res: Response) => {
  const token = generateSessionToken();
  res.json({ token });
});

export default router;
