const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory data store
let tasks = [];

// Metrics tracking
let metrics = {
  requests: 0,
  errors: 0,
  latencies: []
};

// Metrics middleware
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

// Logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
  const avgLatency = metrics.latencies.length > 0 
    ? metrics.latencies.reduce((a, b) => a + b, 0) / metrics.latencies.length 
    : 0;
  const errorRate = metrics.requests > 0 ? (metrics.errors / metrics.requests) * 100 : 0;
  
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
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    tasksCount: tasks.length 
  });
});

// US-001: Create Task
app.post('/api/tasks', (req, res) => {
  try {
    const { title, description } = req.body;
    
    if (!title || title.trim().length === 0) {
      return res.status(400).json({ error: 'Title is required' });
    }
    
    if (title.length > 100) {
      return res.status(400).json({ error: 'Title must be 100 characters or less' });
    }
    
    if (description && description.length > 500) {
      return res.status(400).json({ error: 'Description must be 500 characters or less' });
    }
    
    const newTask = {
      id: uuidv4(),
      title: title.trim(),
      description: description ? description.trim() : '',
      completed: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    tasks.push(newTask);
    console.log(`[INFO] Task created: ${newTask.id}`);
    
    res.status(201).json(newTask);
  } catch (error) {
    console.error('[ERROR] Failed to create task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// US-002: View Task List
app.get('/api/tasks', (req, res) => {
  try {
    const sortedTasks = [...tasks].sort((a, b) => 
      new Date(b.createdAt) - new Date(a.createdAt)
    );
    
    console.log(`[INFO] Retrieved ${sortedTasks.length} tasks`);
    res.status(200).json(sortedTasks);
  } catch (error) {
    console.error('[ERROR] Failed to retrieve tasks:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// US-003: Mark Task as Complete
app.patch('/api/tasks/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { completed } = req.body;
    
    const taskIndex = tasks.findIndex(task => task.id === id);
    
    if (taskIndex === -1) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    if (typeof completed !== 'boolean') {
      return res.status(400).json({ error: 'Completed status must be a boolean' });
    }
    
    tasks[taskIndex].completed = completed;
    tasks[taskIndex].updatedAt = new Date().toISOString();
    
    console.log(`[INFO] Task ${id} status updated to: ${completed}`);
    res.status(200).json(tasks[taskIndex]);
  } catch (error) {
    console.error('[ERROR] Failed to update task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// US-004: Delete Task
app.delete('/api/tasks/:id', (req, res) => {
  try {
    const { id } = req.params;
    const taskIndex = tasks.findIndex(task => task.id === id);
    
    if (taskIndex === -1) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    const deletedTask = tasks.splice(taskIndex, 1)[0];
    console.log(`[INFO] Task deleted: ${id}`);
    
    res.status(200).json({ message: 'Task deleted successfully', task: deletedTask });
  } catch (error) {
    console.error('[ERROR] Failed to delete task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// US-005: Edit Task
app.put('/api/tasks/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { title, description } = req.body;
    
    const taskIndex = tasks.findIndex(task => task.id === id);
    
    if (taskIndex === -1) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    if (!title || title.trim().length === 0) {
      return res.status(400).json({ error: 'Title is required' });
    }
    
    if (title.length > 100) {
      return res.status(400).json({ error: 'Title must be 100 characters or less' });
    }
    
    if (description && description.length > 500) {
      return res.status(400).json({ error: 'Description must be 500 characters or less' });
    }
    
    tasks[taskIndex].title = title.trim();
    tasks[taskIndex].description = description ? description.trim() : '';
    tasks[taskIndex].updatedAt = new Date().toISOString();
    
    console.log(`[INFO] Task updated: ${id}`);
    res.status(200).json(tasks[taskIndex]);
  } catch (error) {
    console.error('[ERROR] Failed to update task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('[ERROR] Unhandled error:', err);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`[INFO] TaskFlow server running on port ${PORT}`);
  console.log(`[INFO] Health check available at http://localhost:${PORT}/health`);
  console.log(`[INFO] Metrics available at http://localhost:${PORT}/metrics`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[INFO] SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('[INFO] Server closed');
    process.exit(0);
  });
});

module.exports = app;
