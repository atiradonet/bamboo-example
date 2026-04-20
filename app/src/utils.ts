import jwt from "jsonwebtoken";

// Hardcoded secrets (Snyk Code: HardcodedSecret)
const JWT_SECRET = "my-jwt-secret-key-do-not-share";
const DB_PASSWORD = "SuperSecret123!";

// Insecure randomness for token generation (Snyk Code: InsecureRandom)
export function generateSessionToken(): string {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

// Code injection via eval (Snyk Code: CodeInjection)
export function processTemplate(input: string): string {
  return eval(input);
}

// XSS — returns unsanitized HTML (Snyk Code: XSS)
export function renderGreeting(name: string): string {
  return "<html><body><h1>Welcome, " + name + "!</h1></body></html>";
}

// JWT signing with hardcoded secret
export function signToken(payload: object): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: "24h" });
}

// JWT verification with hardcoded secret
export function verifyToken(token: string): any {
  return jwt.verify(token, JWT_SECRET);
}
