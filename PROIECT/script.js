const express = require("express");
const path = require("path");
const methodOverride = require("method-override");
const mysql = require("mysql");

const connection = mysql.createConnection({
    host: "localhost",
    port: "3306",
    user: "root",
    password: "password",
    database: "bd_banca_proiect",
    timezone: 'system'
});

connection.connect((err) => {
    if(err) throw err;
    console.log("Connection established.");
});

const port = 3000;
const app = express();

app.use(express.urlencoded({extended: true}));
app.use(express.json());
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));
app.use(methodOverride("_method"));
app.use(express.static(__dirname + '/public'));


app.get("/", (req, res) => {
    let sql = "select table_name from information_schema.tables where table_schema = 'bd_banca_proiect';";
    connection.query(sql, (err, result) => {
        if(err) throw(err);
        res.render("main", {data: result});
    });
});

app.get("/favicon.ico", (req, res) => {
    res.send("favicon.ico error. Restart application.");
});

app.get("/table/:table", (req, res) => {
    const {table} = req.params;
    let sql = `SELECT * FROM ${table}`;
    connection.query(sql, (err, result) => {
        if(err) throw err;
        res.render(`table`, {data: result, table: table, field:""});
    }); 
});

app.get("/table/:table/sort/:field/:mode", (req, res) => {
    const {table, field, mode} = req.params; 
    let sql = `SELECT * FROM ${table} ORDER BY ${field} ${mode}`;
    connection.query(sql, (err, result) => {
        if(err) throw err;
        res.render(`table`, {data: result, table: table, field: field, mode: mode});
    });
});

app.get("/create", (req, res) => {
    let sql = "select table_name from information_schema.tables where table_schema = 'bd_banca_proiect';";
    connection.query(sql, (err, result) => {
        if(err) throw(err);
        res.render("create", {data: result});
    });
});

app.get("/create/:tableName", (req, res) => {
    const {tableName} = req.params;
    let sql = `SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.columns WHERE TABLE_NAME = '${tableName}' AND TABLE_SCHEMA = 'bd_banca_proiect' ORDER BY ORDINAL_POSITION;`;
    connection.query(sql, (err, result) => {
        if(err) throw err;
        res.render("data", {data: result, table: tableName});
    });
});

app.post("/create", (req, res) => {
    const tableName = req.body.tableName;
    const inputData = req.body;
    delete inputData.tableName;
    const cvalues = Object.values(inputData).map(value => {
        if(!isNaN(Date.parse(value))) return `"${value.replace("T", " ")}"`;
        else if((typeof value === 'int' && value[0] != '0') || !isNaN(parseFloat(value))) return value;
        else if(value == "NULL" || value == "") return 'NULL';
        else return `"${value}"`;
    }).join(', ');
    let sql = `INSERT INTO ${tableName} VALUES (${cvalues})`;
    connection.query(sql, (err, result) => {
        if(err) {
            res.redirect("/errorpage?err=1"); 
            console.log(err);
            return;
        }
        res.redirect(`/table/${tableName}`);
    });
});

app.get("/table/:table/edit/:pk/:id", (req, res) => {
    const { table, pk, id } = req.params;
    const datalog = req.query.data_login;
    let sqlDataType = `SELECT data_type FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '${table}' AND column_name = '${pk}';`;
    connection.query(sqlDataType, (errDataType, resultDataType) => {
        if (errDataType) throw errDataType;
        const pkDataType = resultDataType[0].data_type;
        let sql = `SELECT * FROM ${table} WHERE ${pk} = ${pkDataType === 'varchar' || 'date' || 'timestamp' ? "'" + id + "'" : id} ${datalog? "AND data_login = '" + datalog + "'" : ""};`;
        connection.query(sql, (err, result) => {
            if (err) throw err;
            let sql2 = `SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.columns WHERE TABLE_NAME = '${table}' AND TABLE_SCHEMA = 'bd_banca_proiect' ORDER BY ORDINAL_POSITION;`;
            connection.query(sql2, (err2, result2) => {
                if (err2) throw err2;
                res.render("edit", { table: table, pk: pk, id: id, entry: result, fields: result2 });
            });
        });
    });
});

app.patch("/table/:tableName/edit/:pk/:id", (req, res) => {
    const inputData = req.body;
    const {tableName, pk, id} = req.params;
    const datalog = req.query.data_login;
    const setClause = Object.entries(inputData).map(([column, value]) => {
        if(column === 'nr_tel' || column === 'CNP') return `${column} = "${value}"`;
        else if(column === 'id_adresa' || column === 'id_oferta' || column === 'id_card' || column === 'id_tranzactie') return `${column} = ${value}`; 
        else if(!isNaN(Date.parse(value))) return `${column} = "${value.replace("T", " ")}"`;
        else if(typeof value === 'number' || !isNaN(parseFloat(value))) return `${column} = ${value}`;
        else if(value === "NULL" || value === "") return `${column} = NULL`;
        else return `${column} = "${value}"`;
    }).join(', ');
    
    let sql = `UPDATE ${tableName} SET ${setClause} WHERE ${pk} = ${typeof id !== 'number' ? `"${id}"` : id} ${datalog? "AND data_login = '" + datalog + "'" : ""};`;
    connection.query(sql, (err, result) => {
        if(err) {
            res.redirect("/errorpage?err=1");
            console.log(err);
            return;
        }
        res.redirect(`/table/${tableName}`);
    })
});

app.delete("/table/:tableName/edit/:pk/:id", (req, res) => {
    const {tableName, pk, id} = req.params;
    let sql = `DELETE FROM ${tableName} WHERE ${pk} = ${typeof id !== 'number' ? `"${id}"` : id};`;
    connection.query(sql, (err, result) => {
        if(err) {
            res.redirect("/errorpage?err=2");
            console.log(err);
            return;
        }
        res.redirect(`/table/${tableName}`);
    });
});

app.get("/transfers", (req, res) => {
    let sql = `SELECT CONCAT(CL1.NUME, " ", CL1.PRENUME) AS "EXPEDITOR", T.IBAN_EXPEDITOR, T.IBAN_DESTINATAR, CONCAT(CL2.NUME, " ", CL2.PRENUME) AS "DESTINATAR", T.DATA_TRANSFER, T.CANTITATE, T.MONEDA_TRANSFER, CL1.SALARIU AS "SALARIU EXPEDITOR", CL2.SALARIU AS "SALARIU DESTINATAR"
    FROM TRANZACTII T
    JOIN CONTURI C1 ON T.IBAN_EXPEDITOR = C1.IBAN
    JOIN CONTURI C2 ON T.IBAN_DESTINATAR = C2.IBAN
    JOIN CLIENTI CL1 ON C1.CNP = CL1.CNP
    JOIN CLIENTI CL2 ON C2.CNP = CL2.CNP
    WHERE (CL1.SALARIU > 5000 AND CL2.SALARIU > 5000) AND HOUR(DATA_TRANSFER) BETWEEN 9 AND 17;`;
    connection.query(sql, (err, result) => {
        if(err) throw err;
        res.render("transfers", {data: result});
    });
});

app.get("/grouphave", (req, res) => {
    let sql = `SELECT A.ORAS, ROUND(AVG(C.SALARIU), 2) AS "SALARIU MEDIU"
    FROM ADRESE A
    JOIN CLIENTI C ON C.ID_ADRESA = A.ID_ADRESA
    WHERE A.TARA = "RO"
    GROUP BY A.ORAS
    HAVING AVG(C.SALARIU) > 7000
    ORDER BY AVG(C.SALARIU) DESC;`;
    connection.query(sql, (err, result) => {
        if(err) throw(err);
        res.render("grouphave", {data:result});
    });
});

app.get("/search", (req, res) => {
    let sql = "select table_name from information_schema.tables where table_schema = 'bd_banca_proiect';";
    connection.query(sql, (err, result) => {
        if(err) throw(err);
        res.render("search", {data: result});
    });
});

app.get("/search/:tableName", (req, res) => {
    const {tableName} = req.params;
    let sql = `SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.columns WHERE TABLE_NAME = '${tableName}' AND TABLE_SCHEMA = 'bd_banca_proiect' ORDER BY ORDINAL_POSITION;`;
    connection.query(sql, (err, result) => {
        if(err) throw err;
        res.render("searchquery", {data: result, table: tableName});
    });
});

app.post("/search", (req, res) => {
    const tableName = req.body.tableName;
    const inputData = req.body;
    delete inputData.tableName;
    const conditions = [];
    Object.keys(inputData).forEach((key) => {
        if (inputData[key] !== '' && !key.endsWith("_cond")) {
            if(inputData[`${key}_cond`]) conditions.push(`${key} ${inputData[`${key}_cond`]} '${inputData[key]}'`);
            else conditions.push(`${key} = '${inputData[key]}'`);
        }
    });
    let sql = `SELECT * FROM ${tableName} WHERE ${conditions.join(' AND ')};`;
    connection.query(sql, (err, result) => {
        if (err) {
            res.redirect("/errorpage?err=3");
            console.log(err);
            return;
        }
        if(result.length == 0) res.render("nullreturn"); 
        else res.render("table", { data: result, table: tableName, field: null, mode: null });
    });
});

app.get("/devmode", (req, res) => {
    res.render("devmode");
});

app.get("/errorpage", (req, res) => {
    const q = req.query;
    res.render("errorpage", {q: q});
});

app.listen(port, () => {
    console.log(`Listening on port ${port}.`);
}); 