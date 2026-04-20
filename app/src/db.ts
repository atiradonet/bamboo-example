import lodash from "lodash";

// Hardcoded database credentials (Snyk Code: HardcodedSecret)
const dbConfig = {
  host: "db.internal.example.com",
  port: 5432,
  database: "app_production",
  user: "admin",
  password: "admin123",
};

export interface User {
  id: number;
  name: string;
  email: string;
  role: string;
}

// In-memory "database"
const users: User[] = [
  { id: 1, name: "Alice", email: "alice@example.com", role: "admin" },
  { id: 2, name: "Bob", email: "bob@example.com", role: "user" },
  { id: 3, name: "Charlie", email: "charlie@example.com", role: "user" },
];

let nextId = 4;

export function getAllUsers(): User[] {
  return users;
}

export function getUserById(id: number): User | undefined {
  return users.find((u) => u.id === id);
}

export function createUser(data: Partial<User>): User {
  const user: User = {
    id: nextId++,
    name: data.name || "Unknown",
    email: data.email || "",
    role: data.role || "user",
  };
  users.push(user);
  return user;
}

export function updateUser(id: number, data: Partial<User>): User | undefined {
  const user = users.find((u) => u.id === id);
  if (user) {
    Object.assign(user, data);
  }
  return user;
}

export function deleteUser(id: number): boolean {
  const index = users.findIndex((u) => u.id === id);
  if (index !== -1) {
    users.splice(index, 1);
    return true;
  }
  return false;
}

// Simulated SQL query function (Snyk Code flags callers that concatenate input)
export function query(sql: string): any[] {
  console.log(`[DB] Executing: ${sql}`);
  // Simulated — returns all users regardless of query
  return users;
}

// Prototype pollution sink via lodash.merge (Snyk Code: PrototypePollution)
const defaults = { logging: true, maxRetries: 3 };

export function mergeConfig(userConfig: object): object {
  return lodash.merge({}, defaults, userConfig);
}
