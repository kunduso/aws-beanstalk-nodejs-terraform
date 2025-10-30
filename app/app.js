const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 8080;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));

let todos = [];

app.get('/', (req, res) => {
  res.send(`
    <h1>To-Do App</h1>
    <form action="/add" method="post">
      <input type="text" name="todo" placeholder="Add a new task" required>
      <button type="submit">Add</button>
    </form>
    <ul>
      ${todos.map((todo, index) => `
        <li>
          ${todo}
          <form style="display:inline" action="/delete/${index}" method="post">
            <button type="submit">Delete</button>
          </form>
        </li>
      `).join('')}
    </ul>
  `);
});

app.post('/add', (req, res) => {
  todos.push(req.body.todo);
  res.redirect('/');
});

app.post('/delete/:index', (req, res) => {
  todos.splice(req.params.index, 1);
  res.redirect('/');
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});