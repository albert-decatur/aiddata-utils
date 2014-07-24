#!/usr/local/bin/node

// convert Jalaali D/M/YYYY to gregorian YYYY-MM-DD
// this script intended for the Afghanistan DAD
// example use ./jalaali2gregorian.js 1360/5/26
var date = process.argv[2];
var moment = require("moment-jalaali");
m = moment(date, 'jD/jM/jYYYY');
console.log(m.format('YYYY-MM-DD'));
