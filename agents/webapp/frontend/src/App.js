import React, { useState, useEffect } from 'react';

function App() {
  const [data, setData] = useState([]);
  const [formData, setFormData] = useState({ column1: '', column2: '' });
  const [editId, setEditId] = useState(null);

  const API_BASE_URL = `http://${window.location.hostname}:5000`; // Use the backend hostname dynamically

  const fetchData = async () => {
    const response = await fetch(`${API_BASE_URL}/data`);
    const result = await response.json();
    setData(result);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (editId) {
      await fetch(`${API_BASE_URL}/data/${editId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });
      setEditId(null);
    } else {
      await fetch(`${API_BASE_URL}/data`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });
    }
    setFormData({ column1: '', column2: '' });
    fetchData();
  };

  const handleDelete = async (id) => {
    await fetch(`${API_BASE_URL}/data/${id}`, { method: 'DELETE' });
    fetchData();
  };

  const handleEdit = (id, column1, column2) => {
    setEditId(id);
    setFormData({ column1, column2 });
  };

  useEffect(() => {
    fetchData();
  }, []);

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Agent CRUD App</h1>
      <form onSubmit={handleSubmit} className="mb-4">
        <input
          type="text"
          placeholder="Column 1"
          value={formData.column1}
          onChange={(e) => setFormData({ ...formData, column1: e.target.value })}
          className="border p-2 mr-2"
          required
        />
        <input
          type="text"
          placeholder="Column 2"
          value={formData.column2}
          onChange={(e) => setFormData({ ...formData, column2: e.target.value })}
          className="border p-2 mr-2"
          required
        />
        <button type="submit" className="bg-blue-500 text-white px-4 py-2">
          {editId ? 'Update' : 'Add'}
        </button>
      </form>
      <table className="table-auto w-full border-collapse border border-gray-300">
        <thead>
          <tr>
            <th className="border border-gray-300 px-4 py-2">ID</th>
            <th className="border border-gray-300 px-4 py-2">Column 1</th>
            <th className="border border-gray-300 px-4 py-2">Column 2</th>
            <th className="border border-gray-300 px-4 py-2">Actions</th>
          </tr>
        </thead>
        <tbody>
          {data.map((row) => (
            <tr key={row.id}>
              <td className="border border-gray-300 px-4 py-2">{row.id}</td>
              <td className="border border-gray-300 px-4 py-2">{row.column1}</td>
              <td className="border border-gray-300 px-4 py-2">{row.column2}</td>
              <td className="border border-gray-300 px-4 py-2">
                <button
                  onClick={() => handleEdit(row.id, row.column1, row.column2)}
                  className="bg-yellow-500 text-white px-2 py-1 mr-2"
                >
                  Edit
                </button>
                <button
                  onClick={() => handleDelete(row.id)}
                  className="bg-red-500 text-white px-2 py-1"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default App;
