# TaskFlow - Development Guidelines

## Code Quality Standards

### Formatting Conventions
- **Indentation**: 2 spaces (consistent across JavaScript files)
- **Semicolons**: Required at end of statements (backend), optional in React (frontend follows react-scripts defaults)
- **Quotes**: Single quotes for strings in backend, mixed in frontend (follows ESLint react-app config)
- **Line Length**: No strict limit, but keep lines readable (typically under 100 characters)
- **Trailing Commas**: Used in multi-line object/array literals

### Structural Conventions
- **File Organization**: 
  - Backend: Single-file server with middleware → routes → error handling → server startup
  - Frontend: Component-based architecture with separate CSS files per component
- **Module Exports**: CommonJS (`module.exports`) for backend, ES6 modules (`export default`) for frontend
- **Imports Order**: 
  1. External dependencies (express, react)
  2. Internal modules/components
  3. Styles (CSS imports)

### Naming Standards
- **Variables/Functions**: camelCase (`fetchTasks`, `handleCreateTask`, `taskIndex`)
- **Components**: PascalCase (`TaskItem`, `TaskForm`, `TaskList`)
- **Constants**: UPPER_SNAKE_CASE for environment variables (`API_URL`, `PORT`)
- **Files**: 
  - Components: PascalCase matching component name (`TaskItem.js`)
  - Utilities: kebab-case (`server-metrics.js`)
  - Tests: Match source file with `.test.js` suffix (`server.test.js`)

### Documentation Practices
- **Inline Comments**: Used for:
  - User story references (`// US-001: Create Task`)
  - Sprint markers (`// Sprint 2`)
  - Section headers (`// Middleware`, `// Health check endpoint`)
  - Complex logic explanations
- **Console Logging**: Structured format with severity levels:
  - `[INFO]` - Normal operations
  - `[ERROR]` - Error conditions
  - Format: `[LEVEL] Message: details`
- **API Documentation**: Inline comments above route handlers with HTTP method and path

## Semantic Patterns

### Error Handling Pattern (5/5 files)
**Consistent try-catch-finally structure across all API operations:**

```javascript
// Backend pattern
app.post('/api/tasks', (req, res) => {
  try {
    // Validation
    if (!title || title.trim().length === 0) {
      return res.status(400).json({ error: 'Title is required' });
    }
    
    // Business logic
    const newTask = { /* ... */ };
    tasks.push(newTask);
    
    // Success logging
    console.log(`[INFO] Task created: ${newTask.id}`);
    res.status(201).json(newTask);
  } catch (error) {
    // Error logging and response
    console.error('[ERROR] Failed to create task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Frontend pattern
const handleCreateTask = async (taskData) => {
  try {
    const response = await fetch(`${API_URL}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(taskData),
    });
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Failed to create task');
    }
    
    const newTask = await response.json();
    setTasks([newTask, ...tasks]);
    showNotification('Task created successfully!', 'success');
    return true;
  } catch (err) {
    console.error('Error creating task:', err);
    setError(err.message);
    showNotification(err.message, 'error');
    return false;
  }
};
```

**Key characteristics:**
- Always return early on validation failures
- Log both success and error cases
- Provide user-friendly error messages
- Return boolean success indicators from frontend handlers

### Validation Pattern (4/5 files)
**Input validation before processing:**

```javascript
// String validation
if (!title || title.trim().length === 0) {
  return res.status(400).json({ error: 'Title is required' });
}

// Length validation
if (title.length > 100) {
  return res.status(400).json({ error: 'Title must be 100 characters or less' });
}

// Type validation
if (typeof completed !== 'boolean') {
  return res.status(400).json({ error: 'Completed status must be a boolean' });
}

// Frontend validation with error state
const newErrors = {};
if (!editTitle.trim()) {
  newErrors.title = 'Title is required';
} else if (editTitle.length > 100) {
  newErrors.title = 'Title must be 100 characters or less';
}
if (Object.keys(newErrors).length > 0) {
  setErrors(newErrors);
  return;
}
```

**Validation rules:**
- Title: Required, trimmed, max 100 characters
- Description: Optional, trimmed, max 500 characters
- Completed: Boolean type check
- Always trim whitespace before validation

### State Management Pattern (3/3 frontend files)
**React hooks for state management:**

```javascript
// Multiple related state variables
const [tasks, setTasks] = useState([]);
const [filter, setFilter] = useState('all');
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);
const [notification, setNotification] = useState(null);

// Edit mode state
const [isEditing, setIsEditing] = useState(false);
const [editTitle, setEditTitle] = useState(task.title);
const [editDescription, setEditDescription] = useState(task.description);
const [errors, setErrors] = useState({});

// State updates with immutability
setTasks([newTask, ...tasks]); // Prepend new task
setTasks(tasks.map(task => 
  task.id === taskId ? updatedTask : task
)); // Update specific task
setTasks(tasks.filter(task => task.id !== taskId)); // Remove task
```

**State patterns:**
- Use separate state variables for different concerns
- Initialize with appropriate default values
- Update state immutably (spread operator, map, filter)
- Clear error/notification state after operations

### Middleware Pattern (2/2 backend files)
**Express middleware chain:**

```javascript
// Global middleware
app.use(cors());
app.use(express.json());

// Custom logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// Metrics tracking middleware
app.use((req, res, next) => {
  const start = Date.now();
  metrics.requests++;
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    metrics.latencies.push(duration);
    if (metrics.latencies.length > 1000) metrics.latencies.shift();
    if (res.statusCode >= 400) metrics.errors++;
  });
  
  next();
});

// Error handling middleware (last)
app.use((err, req, res, next) => {
  console.error('[ERROR] Unhandled error:', err);
  res.status(500).json({ error: 'Something went wrong!' });
});
```

**Middleware order:**
1. CORS and body parsing
2. Logging
3. Metrics/monitoring
4. Routes
5. Error handling (must be last)

### RESTful API Pattern (2/2 backend files)
**Consistent REST endpoint design:**

```javascript
// Resource-based URLs
GET    /api/tasks       // List all tasks
POST   /api/tasks       // Create task
PATCH  /api/tasks/:id   // Partial update (status)
PUT    /api/tasks/:id   // Full update (edit)
DELETE /api/tasks/:id   // Delete task

// Health/monitoring endpoints
GET    /health          // Health check
GET    /metrics         // Prometheus metrics

// HTTP status codes
201 - Created (POST success)
200 - OK (GET, PATCH, PUT, DELETE success)
204 - No Content (DELETE success in tests)
400 - Bad Request (validation errors)
404 - Not Found (resource not found)
500 - Internal Server Error (unexpected errors)

// Response format
// Success: { ...data } or { message: '...', ...data }
// Error: { error: 'Error message' }
```

### Async/Await Pattern (3/3 frontend files)
**Modern async handling with fetch API:**

```javascript
// Async function with error handling
const fetchTasks = async () => {
  try {
    setLoading(true);
    const response = await fetch(`${API_URL}/tasks`);
    if (!response.ok) {
      throw new Error('Failed to fetch tasks');
    }
    const data = await response.json();
    setTasks(data);
    setError(null);
  } catch (err) {
    console.error('Error fetching tasks:', err);
    setError('Failed to load tasks. Please try again.');
  } finally {
    setLoading(false);
  }
};

// POST with JSON body
const response = await fetch(`${API_URL}/tasks`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(taskData),
});
```

**Async patterns:**
- Always use try-catch with async/await
- Check `response.ok` before parsing JSON
- Use finally for cleanup (loading states)
- Parse error responses for user-friendly messages

### Component Composition Pattern (3/3 frontend files)
**React component hierarchy with props:**

```javascript
// Parent component (App.js)
<TaskForm onCreateTask={handleCreateTask} />
<TaskFilter 
  currentFilter={filter}
  onFilterChange={setFilter}
  activeCount={activeCount}
  completedCount={completedCount}
  totalCount={tasks.length}
/>
<TaskList 
  tasks={filteredTasks}
  onToggleComplete={handleToggleComplete}
  onDeleteTask={handleDeleteTask}
  onEditTask={handleEditTask}
/>

// Child component (TaskList.js)
{tasks.map(task => (
  <TaskItem
    key={task.id}
    task={task}
    onToggleComplete={onToggleComplete}
    onDeleteTask={onDeleteTask}
    onEditTask={onEditTask}
  />
))}
```

**Composition principles:**
- Pass data down via props
- Pass callbacks up for actions
- Use key prop for list items (task.id)
- Destructure props in function parameters

### Metrics Collection Pattern (1/2 backend files)
**Prometheus-compatible metrics exposition:**

```javascript
// In-memory metrics storage
let metrics = {
  requests: 0,
  errors: 0,
  latencies: []
};

// Metrics calculation
const avgLatency = metrics.latencies.length > 0 
  ? metrics.latencies.reduce((a, b) => a + b, 0) / metrics.latencies.length 
  : 0;
const errorRate = metrics.requests > 0 
  ? (metrics.errors / metrics.requests) * 100 
  : 0;

// Prometheus text format
const prometheusMetrics = `
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total ${metrics.requests}

# HELP http_errors_total Total HTTP errors
# TYPE http_errors_total counter
http_errors_total ${metrics.errors}

# HELP http_request_duration_ms Average request duration in milliseconds
# TYPE http_request_duration_ms gauge
http_request_duration_ms ${avgLatency.toFixed(2)}

# HELP http_error_rate_percent HTTP error rate percentage
# TYPE http_error_rate_percent gauge
http_error_rate_percent ${errorRate.toFixed(2)}

# HELP tasks_total Total number of tasks
# TYPE tasks_total gauge
tasks_total ${tasks.length}
`;

res.set('Content-Type', 'text/plain');
res.send(prometheusMetrics);
```

**Metrics patterns:**
- Use counters for cumulative values (requests, errors)
- Use gauges for current values (latency, error rate, task count)
- Include HELP and TYPE comments
- Format numbers with `.toFixed()` for consistency
- Set Content-Type to 'text/plain'

## Internal API Usage

### Express.js API Patterns

```javascript
// Route definition with HTTP method
app.get('/api/tasks', (req, res) => { /* ... */ });
app.post('/api/tasks', (req, res) => { /* ... */ });
app.patch('/api/tasks/:id', (req, res) => { /* ... */ });
app.put('/api/tasks/:id', (req, res) => { /* ... */ });
app.delete('/api/tasks/:id', (req, res) => { /* ... */ });

// Request data access
const { title, description } = req.body;  // POST/PUT/PATCH body
const { id } = req.params;                // URL parameters

// Response methods
res.status(201).json(newTask);            // JSON response with status
res.status(400).json({ error: 'msg' });   // Error response
res.set('Content-Type', 'text/plain');    // Set header
res.send(prometheusMetrics);              // Send text response

// Middleware registration
app.use(cors());                          // Global middleware
app.use(express.json());                  // Body parser
app.use((req, res, next) => { next(); }); // Custom middleware
```

### React Hooks API Patterns

```javascript
// State management
const [state, setState] = useState(initialValue);
setState(newValue);                       // Direct update
setState(prev => [...prev, newItem]);     // Functional update

// Side effects
useEffect(() => {
  fetchTasks();                           // Run on mount
}, []);                                   // Empty deps = mount only

useEffect(() => {
  // Run when dependency changes
}, [dependency]);

// Event handlers
onChange={(e) => setValue(e.target.value)}
onClick={() => handleClick(id)}
onSubmit={(e) => { e.preventDefault(); handleSubmit(); }}
```

### Array/Object Manipulation Patterns

```javascript
// Immutable array operations
[newItem, ...existingArray]               // Prepend
array.map(item => item.id === id ? updated : item)  // Update
array.filter(item => item.id !== id)      // Remove
[...array].sort((a, b) => b.value - a.value)  // Sort (copy first)

// Array methods
array.findIndex(item => item.id === id)   // Find index
array.find(item => item.id === id)        // Find item
array.splice(index, 1)                    // Remove at index (mutates)

// Object operations
{ ...existingObject, newProp: value }     // Spread and override
Object.keys(errors).length                // Count properties
```

## Code Idioms

### Conditional Early Returns
```javascript
// Validation with early returns
if (!title || title.trim().length === 0) {
  return res.status(400).json({ error: 'Title is required' });
}
if (taskIndex === -1) {
  return res.status(404).json({ error: 'Task not found' });
}
// Continue with main logic...
```

### Ternary Operators for Defaults
```javascript
const PORT = process.env.PORT || 5000;
const API_URL = process.env.REACT_APP_API_URL || '/api';
description: description ? description.trim() : ''
priority: priority || 'medium'
```

### Template Literals for Logging
```javascript
console.log(`[INFO] Task created: ${newTask.id}`);
console.log(`[${timestamp}] ${req.method} ${req.path}`);
console.error('[ERROR] Failed to create task:', error);
```

### Destructuring Assignments
```javascript
const { title, description } = req.body;
const { id } = req.params;
const { tasks, filter, loading } = this.state;
```

### Spread Operator Usage
```javascript
const sortedTasks = [...tasks].sort(...);  // Copy before mutating
setTasks([newTask, ...tasks]);             // Prepend to array
tasks[taskIndex] = { ...tasks[taskIndex], ...req.body };  // Merge objects
```

### Arrow Functions
```javascript
// Inline callbacks
tasks.map(task => task.id === id ? updated : task)
tasks.filter(task => !task.completed)
setTimeout(() => setNotification(null), 3000)

// Event handlers
onClick={() => handleClick(id)}
onChange={(e) => setValue(e.target.value)}

// Async functions
const fetchTasks = async () => { /* ... */ };
```

## Testing Patterns

### Jest Test Structure
```javascript
describe('Feature/Component Tests', () => {
  beforeEach(() => {
    // Reset state before each test
    tasks = [];
  });

  describe('Specific Endpoint/Function', () => {
    it('should perform expected behavior', async () => {
      // Arrange
      const taskData = { title: 'Test Task' };
      
      // Act
      const res = await request(app)
        .post('/api/tasks')
        .send(taskData);
      
      // Assert
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.title).toBe(taskData.title);
    });
  });
});
```

### Supertest API Testing
```javascript
// GET request
const res = await request(app).get('/api/tasks');

// POST request with body
const res = await request(app)
  .post('/api/tasks')
  .send({ title: 'Test Task' });

// PATCH request
const res = await request(app)
  .patch(`/api/tasks/${taskId}`)
  .send({ completed: true });

// DELETE request
const res = await request(app).delete(`/api/tasks/${taskId}`);

// Assertions
expect(res.statusCode).toBe(200);
expect(res.body).toEqual([]);
expect(res.body).toHaveProperty('id');
```

## Common Annotations

### User Story References
```javascript
// US-001: Create Task
// US-002: View Task List
// US-003: Mark Task as Complete
// US-004: Delete Task
// US-005: Edit Task
// US-006: Filter tasks by status
```

### Sprint Markers
```javascript
// Sprint 1 - simple implementation
// Sprint 2
// (Sprint 2)
```

### Section Headers
```javascript
// Middleware
// Health check endpoint
// Logging middleware for monitoring
// Error handling middleware
// Start server
// Graceful shutdown
```

## Best Practices Summary

1. **Always validate input** before processing
2. **Use try-catch** for all async operations and route handlers
3. **Log operations** with structured format and severity levels
4. **Return early** on validation failures or errors
5. **Trim user input** before validation and storage
6. **Use immutable updates** for React state
7. **Provide user-friendly error messages** in responses
8. **Include health check endpoints** for monitoring
9. **Implement graceful shutdown** handlers (SIGTERM)
10. **Use environment variables** for configuration
11. **Sort data** before returning (newest first)
12. **Include timestamps** in data models (createdAt, updatedAt)
13. **Use UUID** for unique identifiers
14. **Set appropriate HTTP status codes** for all responses
15. **Clear temporary state** (notifications, errors) after timeout
