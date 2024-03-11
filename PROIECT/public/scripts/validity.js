const helper = document.querySelector("#helper");
const table = helper.dataset.table;

function setRequired(elemId) {
    const elem = document.querySelector(elemId);
    if(elem) elem.required = true;
}

function isnum(string) {
    for (let i = 0; i < string.length; i++) {
       var ascii = string.charCodeAt(i);
       if (ascii < 48 || ascii > 57) {
          return false;
       }
    }
    return true;
 }

 function validAge(birthday) {
    const BDObj = new Date(birthday);
    const currDate = new Date();
    let age = currDate.getFullYear() - BDObj.getFullYear();
    const bdayOccur = (currDate.getMonth() > BDObj.getMonth() || (currDate.getMonth() === BDObj.getMonth() && currDate.getDate() >= BDObj.getDate()));
    age = bdayOccur ? age : age - 1;
    return age >= 16;
 }

const form = document.querySelector("#insertForm");

const Elements = {
    "activitati_online": ["#CNP", "#data_login"],
    "adrese": ["#tara", "#oras", "#strada", "#id_adresa"],
    "carduri": ["#id_card", "#id_oferta", "#cod_card", "#tip_card", "#IBAN"],
    "clienti": ["#CNP", "#nume", "#prenume", "#data_nasterii", "#nr_tel", "#id_adresa"],
    "conturi": ["#IBAN", "#moneda_cont", "#CNP"],
    "oferte": ["#id_oferta", "#nume_oferta"],
    "tranzactii": ["#id_tranzactie", "#iban_expeditor", "#iban_destinatar", "data_transfer", "cantitate", "moneda_transfer"]
};

const requiredElements = Elements[table];

if (requiredElements) {
    requiredElements.forEach(setRequired);
}

if(table == "clienti") {
    const citizen = document.querySelector("#cetatenie");
    const gen = document.querySelector("#gen");
    const cnp = document.querySelector("#CNP");
    const bday = document.querySelector("#data_nasterii");
    const tel = document.querySelector("#nr_tel");
    const email = document.querySelector("#email");
    if(citizen.value == "ROU") {
        let year, month, day;
        cnp.addEventListener("keydown", (event) => {
            if(['1', '5'].includes(cnp.value[0])) gen.value = "M";
            if(['2', '6'].includes(cnp.value[0])) gen.value = "F";
            if(cnp.value.length >= 7) {
                if(['1', '2'].includes(cnp.value[0])) year = "19" + cnp.value.substring(1, 3);
                else year = "20" + cnp.value.substring(1, 3);
                month = cnp.value.substring(3, 5);
                day = cnp.value.substring(5, 7);
                const isoDate = `${year}-${month}-${day}`
                bday.value = isoDate;
            }
        });
    }
    email.type = "email";
}


form.addEventListener('submit', (event) => {
    switch(table) {
        case "activitati_online":
            const datalog = document.querySelector("#data_login");
            const datalogDate = datalog.value;
            const currDate = new Date();
            if(datalogDate > currDate) {
                datalog.style.border = "3px solid red";
                alert("Data de login invalida! Data logarii nu poate fi din viitor");
                event.preventDefault();
            }
            break;
        case "carduri":
            const cardcode = document.querySelector("#cod_card");
            const iban = document.querySelector("#IBAN");
            if(cardcode.value.length != 16) {
                cardcode.style.border = "3px solid red";
                alert("Cod_card invalid! Codul (numarul) cardului trebuie sa contina 16 cifre!");
                event.precentDefault();
            }
            if(iban.value.slice(0, 2) != "RO" || iban.value.slice(4, 8) != "MBNK") {
                iban.style.border = "3px solid red";
                alert("IBAN invalid! Verificati structura IBAN-ului introdus.");
                event.preventDefault();
            } 
            break;
        case "clienti":
            const citizen = document.querySelector("#cetatenie");
            const gen = document.querySelector("#gen");
            const cnp = document.querySelector("#CNP");
            const bday = document.querySelector("#data_nasterii");
            const tel = document.querySelector("#nr_tel");
            if(citizen.value == "ROU") {
                if((gen.value == 'M' && !['1', '5'].includes(cnp.value[0])) || (gen.value == 'F' && !['2', '6'].includes(cnp.value[0]))) {
                    alert("Verificati corectitudinea datelor introduse! Genul selectat nu corespunde CNP-ului romanesc!");
                    citizen.style.border = "3px solid red";
                    gen.style.border = "3px solid red";
                    cnp.style.border = "3px solid red";
                    event.preventDefault();
                } 
                let year, month, day;
                if(['1', '2'].includes(cnp.value[0])) year = "19" + cnp.value.substring(1, 3);
                else year = "20" + cnp.value.substring(1, 3);
                month = cnp.value.substring(3, 5);
                day = cnp.value.substring(5, 7);
                const isoDate = `${year}-${month}-${day}`
                if(isoDate != bday.value) {
                    alert("Verificati corectitudinea datelor introduse! Data nasterii nu corespunde CNP-ului romanesc!");
                    citizen.style.border = "3px solid red";
                    cnp.style.border = "3px solid red";
                    bday.style.border = "3px solid red";
                    event.preventDefault();
                }
            }
            if(!isnum(tel.value)) {
                alert("Numarul de telefon este invalid!");
                tel.style.border = "3px solid red";
                event.preventDefault();
            }
            if(!validAge(bday.value)) {
                alert("Clinetul trebuie sa aiba minim 16 ani!");
                bday.style.border = "3px solid red";
                event.preventDefault();
            }
            break;
        case "tranzactii":
            const datatranz = document.querySelector("#data_transfer");
            const datatranzDate = new Date(datatranz.value);
            const currDatetranz = new Date();
            if(datatranzDate > currDatetranz) {
                datatranz.style.border = "3px solid red";
                alert("Datade transfer invalida! Data ltransferului nu poate fi din viitor.");
                event.preventDefault();
            }
    }
});



