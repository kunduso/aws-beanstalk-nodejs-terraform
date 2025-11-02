const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 8080;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));

// Simple HTML escaping function to prevent XSS
function escapeHtml(unsafe) {
  if (unsafe == null) return '';
  return String(unsafe)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

let todos = [];

app.get('/', (req, res) => {
  res.send(`
    <h1>To-Do App</h1>
    <form action="/add" method="post">
      <input type="text" name="todo" placeholder="Add a new task" required maxlength="200">
      <button type="submit">Add</button>
    </form>
    <ul>
      ${todos.map((todo, index) => `
        <li>
          ${escapeHtml(todo)}
          <form style="display:inline" action="/delete/${index}" method="post">
            <button type="submit">Delete</button>
          </form>
        </li>
      `).join('')}
    </ul>
  `);
});

app.post('/add', (req, res) => {
  const todo = req.body.todo;
  if (todo && todo.trim().length > 0 && todo.length <= 200) {
    todos.push(todo.trim());
  }
  res.redirect('/');
});

app.post('/delete/:index', (req, res) => {
  const index = parseInt(req.params.index);
  if (index >= 0 && index < todos.length) {
    todos.splice(index, 1);
  }
  res.redirect('/');
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});