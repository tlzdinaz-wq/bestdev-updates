// FiveM encodes empty Lua tables as objects. The tablet expects list fields
// to stay arrays; normalize at the boundary before the React listener runs.
(function () {
  'use strict';
  function list(value) {
    if (Array.isArray(value)) return value;
    if (!value || typeof value !== 'object') return [];
    return Object.values(value);
  }
  function role(value) {
    if (!value || typeof value !== 'object') return;
    value.permissions = list(value.permissions);
  }
  window.addEventListener('message', function (event) {
    var message = event && event.data;
    if (!message || message.action !== 'bossPanel:open') return;
    var data = message.data;
    if (!data || !data.company || !data.player) return;
    var company = data.company;
    ['employees', 'roles', 'permissions', 'invoices', 'revenue', 'expenses', 'chests', 'lockers'].forEach(function (key) {
      company[key] = list(company[key]);
    });
    company.roles.forEach(role);
    company.employees.forEach(function (employee) {
      if (employee) role(employee.role);
    });
    ['farming', 'ltd', 'restaurant'].forEach(function (key) {
      if (company[key] && typeof company[key] === 'object') {
        company[key].logs = list(company[key].logs);
      }
    });
    role(data.player.role);
  });
}());
