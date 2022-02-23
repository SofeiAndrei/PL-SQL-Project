--6.
--Afisati cati soldati fac parte din plutonul X si sunt ofiteri (maior,capitan,locotenent)
--folosind 2 tabele in care tinem soldatii din plutonul 1 respectiv ofiterii
CREATE OR REPLACE FUNCTION nr_ofiteri_plutonul_x
  (pluton pluton.cod_pluton%type)
RETURN NUMBER
IS
  nr_ofiteri_din_pluton number(3) :=0;
  nr_soldati_din_pluton number(3) :=0;
  --tablou indexat
  type lista_soldati is table of soldat%rowtype index by pls_integer; 
  soldati_plutonul_x lista_soldati; 
  --tablou imbricat
  type lista_ofiteri is table of soldat%rowtype;
  ofiteri lista_ofiteri := lista_ofiteri();
BEGIN
  select count(*) into nr_soldati_din_pluton
  from soldat
  where cod_pluton = pluton;
  
  select * bulk collect into soldati_plutonul_x
  from soldat
  where cod_pluton = pluton;
  
  select * bulk collect into ofiteri
  from soldat
  where cod_rang = 6 or cod_rang = 7 or cod_rang = 8;
  
  for i in soldati_plutonul_x.FIRST..soldati_plutonul_x.LAST loop
    for j in ofiteri.FIRST..ofiteri.LAST loop
      if soldati_plutonul_x(i).cod_soldat = ofiteri(j).cod_soldat then
        nr_ofiteri_din_pluton := nr_ofiteri_din_pluton + 1;
      end if;
    end loop;
  end loop;
  return nr_ofiteri_din_pluton;
EXCEPTION
  WHEN NO_DATA_FOUND then
  RAISE_APPLICATION_ERROR(-20000, 'Nu exista plutonul dat');
  WHEN OTHERS then
  RAISE_APPLICATION_ERROR(-20001, 'Alta eroare');
END nr_ofiteri_plutonul_x;
/
set serveroutput on;
BEGIN
  DBMS_OUTPUT.PUT_LINE(nr_ofiteri_plutonul_x(1));
END;
/

--7.
--Folosind un cursor afisati pentru fiecare pluton 
--cati soldati are si media de varsta pe fiecare pluton 
CREATE OR REPLACE PROCEDURE detalii_plutoane
IS
  plutonul pluton.cod_pluton%TYPE;
  nr_soldati_pluton number(5);
  varsta_medie float(10);
  CURSOR cursor_detalii_plutoane is
    select p.cod_pluton codul_plutonului, count(s.cod_soldat) nr_soldati, avg(s.varsta) medie_varsta
    from pluton p, soldat s
    where p.cod_pluton = s.cod_pluton(+)
    group by p.cod_pluton;
BEGIN
  OPEN cursor_detalii_plutoane;
  loop
    fetch cursor_detalii_plutoane into plutonul,nr_soldati_pluton,varsta_medie;
    exit when cursor_detalii_plutoane%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('In plutonul ' || plutonul || ' sunt ' || nr_soldati_pluton || ' soldati cu varsta medie de ' || varsta_medie || ' ani.');
  end loop;
  CLOSE cursor_detalii_plutoane;
END detalii_plutoane;
/
set serveroutput on;
BEGIN
  detalii_plutoane;
END;
/


--8.
--Afisati arma pe care o foloseste soldatul cu un prenume dat
CREATE OR REPLACE FUNCTION ce_arma_foloseste
  (prenume_soldat soldat.prenume%TYPE DEFAULT 'Andrei-Adrian')
RETURN VARCHAR2
IS
  cod_soldat_dat soldat.cod_soldat%TYPE;
  nume_arma arma.nume_model%TYPE;
BEGIN
  select s.cod_soldat into cod_soldat_dat
  from soldat s
  where s.prenume = prenume_soldat;
  
  select a.nume_model into nume_arma
  from soldat s, echipament e, arma a
  where s.prenume = prenume_soldat and
  s.cod_echipament = e.cod_echipament and
  e.cod_arma = a.cod_arma;
  
  return nume_arma;
EXCEPTION
  WHEN NO_DATA_FOUND then
  RAISE_APPLICATION_ERROR(-20000, 'Nu exista niciun soldat cu prenumele dat');
  WHEN TOO_MANY_ROWS then
  RAISE_APPLICATION_ERROR(-20001, 'Sunt mai multi soldati cu acelasi prenume');
  WHEN OTHERS then
  RAISE_APPLICATION_ERROR(-20002, 'Alta eroare');
END ce_arma_foloseste;
/

set serveroutput on;
BEGIN
  DBMS_OUTPUT.PUT_LINE(ce_arma_foloseste);
END;
/
set serveroutput on;
BEGIN
  DBMS_OUTPUT.PUT_LINE(ce_arma_foloseste('Jacob'));
END;
/
set serveroutput on;
BEGIN
  DBMS_OUTPUT.PUT_LINE(ce_arma_foloseste('Nu exist'));
END;
/


--9.
--Afisati in ce regiune este stationat soldatul care foloseste echipamentul cu codul dat
CREATE OR REPLACE PROCEDURE regiune_soldat
  (echipament_dat echipament.cod_echipament%TYPE)
IS
  cod_soldat_dat soldat.cod_soldat%TYPE;
  regiunea regiune.nume_regiune%TYPE;
BEGIN
  select s.cod_soldat into cod_soldat_dat
  from soldat s
  where s.cod_echipament = echipament_dat;
  
  select r.nume_regiune into regiunea
  from soldat s, pluton p, oras o, tara t, regiune r
  where s.cod_echipament = echipament_dat and
  s.cod_pluton = p.cod_pluton and
  p.cod_oras = o.cod_oras and
  o.cod_tara = t.cod_tara and
  t.cod_regiune = r.cod_regiune;
  DBMS_OUTPUT.PUT_LINE(regiunea);
EXCEPTION
  WHEN NO_DATA_FOUND then
  RAISE_APPLICATION_ERROR(-20000, 'Nu exista niciu soldat care foloseste echipamentul cu codul dat');
  WHEN TOO_MANY_ROWS then
  RAISE_APPLICATION_ERROR(-20001, 'Sunt mai multi soldati care folosesc acelasi echipament');
  WHEN OTHERS then
  RAISE_APPLICATION_ERROR(-20002, 'Alta eroare');
END regiune_soldat;
/


set serveroutput on;
BEGIN
  regiune_soldat(2);
END;
/
set serveroutput on;
BEGIN
  regiune_soldat(3);
END;
/
set serveroutput on;
BEGIN
  regiune_soldat(9);
END;
/

--10
--Trigger care sa nu permita modificarea datelor din tabelul soldat daca sunt efectuate in week-end(sambata/duminica) sau joia
CREATE OR REPLACE TRIGGER trigger_sambata_si_duminica
  BEFORE INSERT OR UPDATE OR DELETE ON soldat
BEGIN
  if TO_CHAR(SYSDATE, 'D') = 1 then
    RAISE_APPLICATION_ERROR(-20000,'tabelul SOLDAT nu poate fi actualizat duminica');
  elsif TO_CHAR(SYSDATE, 'D') = 7 then
    RAISE_APPLICATION_ERROR(-20001,'tabelul SOLDAT nu poate fi actualizat sambata');
  elsif TO_CHAR(SYSDATE, 'D') = 5 then
    RAISE_APPLICATION_ERROR(-20002,'tabelul SOLDAT nu poate fi actualizat joia');
  end if;
END;
/

DROP TRIGGER trigger_sambata_si_duminica;


--11
--Trigger care sa nu permita micsorarea varstei unui soldat
CREATE OR REPLACE TRIGGER trigger_micsorare_varsta
  BEFORE UPDATE OF varsta ON soldat
  FOR EACH ROW
  WHEN (NEW.varsta < OLD.varsta)
BEGIN
  RAISE_APPLICATION_ERROR(-20000,'varsta unui soldat nu poate fi micsorata');
END;
/

update soldat
set varsta = varsta-1;
DROP TRIGGER trigger_micsorare_varsta;




--12
--Trigger care afiseaza date despre instructiunile apelate
CREATE OR REPLACE TRIGGER trigger_date_utilizator
  AFTER CREATE OR DROP OR ALTER ON SCHEMA
BEGIN
    DBMS_OUTPUT.PUT_LINE('Utilizator: ' || SYS.LOGIN_USER);
    DBMS_OUTPUT.PUT_LINE('Comanda Folosita: ' || SYS.SYSEVENT);
    DBMS_OUTPUT.PUT_LINE('Numele Tabelului Afectat: ' || SYS.DICTIONARY_OBJ_NAME);
    DBMS_OUTPUT.PUT_LINE('Data: ' || SYSDATE);
end;
/
create table test (id_test number(3), alta_data number(4));
drop table test;
DROP TRIGGER trigger_date_utilizator; 

--13
CREATE OR REPLACE PACKAGE pachet_simplu AS
  FUNCTION nr_ofiteri_plutonul_x_pct(pluton pluton.cod_pluton%type)
    RETURN NUMBER;
  PROCEDURE detalii_plutoane_pct;
  FUNCTION ce_arma_foloseste_pct(prenume_soldat soldat.prenume%TYPE DEFAULT 'Andrei-Adrian')
    RETURN VARCHAR2;
  PROCEDURE regiune_soldat_pct(echipament_dat echipament.cod_echipament%TYPE);
END pachet_simplu;
/
CREATE OR REPLACE PACKAGE BODY pachet_simplu AS
  FUNCTION nr_ofiteri_plutonul_x_pct(pluton pluton.cod_pluton%type)
  RETURN NUMBER
  IS
    nr_ofiteri_din_pluton number(3) :=0;
    nr_soldati_din_pluton number(3) :=0;
    --tablou indexat
    type lista_soldati is table of soldat%rowtype index by pls_integer; 
    soldati_plutonul_x lista_soldati; 
    --tablou imbricat
    type lista_ofiteri is table of soldat%rowtype;
    ofiteri lista_ofiteri := lista_ofiteri();
  BEGIN
    select count(*) into nr_soldati_din_pluton
    from soldat
    where cod_pluton = pluton;
    
    select * bulk collect into soldati_plutonul_x
    from soldat
    where cod_pluton = pluton;
    
    select * bulk collect into ofiteri
    from soldat
    where cod_rang = 6 or cod_rang = 7 or cod_rang = 8;
    
    for i in soldati_plutonul_x.FIRST..soldati_plutonul_x.LAST loop
      for j in ofiteri.FIRST..ofiteri.LAST loop
        if soldati_plutonul_x(i).cod_soldat = ofiteri(j).cod_soldat then
          nr_ofiteri_din_pluton := nr_ofiteri_din_pluton + 1;
        end if;
      end loop;
    end loop;
    return nr_ofiteri_din_pluton;
  EXCEPTION
    WHEN NO_DATA_FOUND then
    RAISE_APPLICATION_ERROR(-20000, 'Nu exista plutonul dat');
    WHEN OTHERS then
    RAISE_APPLICATION_ERROR(-20001, 'Alta eroare');
  END nr_ofiteri_plutonul_x_pct;
  
  PROCEDURE detalii_plutoane_pct
  IS
    plutonul pluton.cod_pluton%TYPE;
    nr_soldati_pluton number(5);
    varsta_medie float(10);
    CURSOR cursor_detalii_plutoane is
      select p.cod_pluton codul_plutonului, count(s.cod_soldat) nr_soldati, avg(s.varsta) medie_varsta
      from pluton p, soldat s
      where p.cod_pluton = s.cod_pluton(+)
      group by p.cod_pluton;
  BEGIN
    OPEN cursor_detalii_plutoane;
    loop
      fetch cursor_detalii_plutoane into plutonul,nr_soldati_pluton,varsta_medie;
      exit when cursor_detalii_plutoane%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('In plutonul ' || plutonul || ' sunt ' || nr_soldati_pluton || ' soldati cu varsta medie de ' || varsta_medie || ' ani.');
    end loop;
    CLOSE cursor_detalii_plutoane;
  END detalii_plutoane_pct;
  
  FUNCTION ce_arma_foloseste_pct(prenume_soldat soldat.prenume%TYPE DEFAULT 'Andrei-Adrian')
  RETURN VARCHAR2
  IS
    cod_soldat_dat soldat.cod_soldat%TYPE;
    nume_arma arma.nume_model%TYPE;
  BEGIN
    select s.cod_soldat into cod_soldat_dat
    from soldat s
    where s.prenume = prenume_soldat;
    
    select a.nume_model into nume_arma
    from soldat s, echipament e, arma a
    where s.prenume = prenume_soldat and
    s.cod_echipament = e.cod_echipament and
    e.cod_arma = a.cod_arma;
    
    return nume_arma;
  EXCEPTION
    WHEN NO_DATA_FOUND then
    RAISE_APPLICATION_ERROR(-20000, 'Nu exista niciun soldat cu prenumele dat');
    WHEN TOO_MANY_ROWS then
    RAISE_APPLICATION_ERROR(-20001, 'Sunt mai multi soldati cu acelasi prenume');
    WHEN OTHERS then
    RAISE_APPLICATION_ERROR(-20002, 'Alta eroare');
  END ce_arma_foloseste_pct;
  
  PROCEDURE regiune_soldat_pct(echipament_dat echipament.cod_echipament%TYPE)
  IS
    cod_soldat_dat soldat.cod_soldat%TYPE;
    regiunea regiune.nume_regiune%TYPE;
  BEGIN
    select s.cod_soldat into cod_soldat_dat
    from soldat s
    where s.cod_echipament = echipament_dat;
    
    select r.nume_regiune into regiunea
    from soldat s, pluton p, oras o, tara t, regiune r
    where s.cod_echipament = echipament_dat and
    s.cod_pluton = p.cod_pluton and
    p.cod_oras = o.cod_oras and
    o.cod_tara = t.cod_tara and
    t.cod_regiune = r.cod_regiune;
    DBMS_OUTPUT.PUT_LINE(regiunea);
  EXCEPTION
    WHEN NO_DATA_FOUND then
    RAISE_APPLICATION_ERROR(-20000, 'Nu exista niciu soldat care foloseste echipamentul cu codul dat');
    WHEN TOO_MANY_ROWS then
    RAISE_APPLICATION_ERROR(-20001, 'Sunt mai multi soldati care folosesc acelasi echipament');
    WHEN OTHERS then
    RAISE_APPLICATION_ERROR(-20002, 'Alta eroare');
  END regiune_soldat_pct;
END pachet_simplu;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE(pachet_simplu.nr_ofiteri_plutonul_x_pct(1));
  pachet_simplu.detalii_plutoane_pct;
  DBMS_OUTPUT.PUT_LINE(pachet_simplu.ce_arma_foloseste_pct('Alan'));
  pachet_simplu.regiune_soldat_pct(2);
END;
/
set serveroutput on;

--14
--Tip Date Tablou Imbricat in care tin minte indicii plutoanelor
--Tip Date Record in care tinem minte informatii despre perechea rezultatelor la functie
--Tip Date Record in care tinem minte informatii despre toti soldatii din plutonul respectiv(cod_soldat, nume, prenume, cod_superior)
--Tip Date Tablou Indexat In care pentru fiecare pluton tinem minte detalii despre toti soldatii
--Tip Date Tablou Imbricat in care tinem minte rezultatele pentru fiecare apel al functiei Aflare Cel Mai Mare Superior ca record pereche(soldat, superior maximi)
--Functie Aflare Pluton
--Functie Aflare numar de medalii
--Functie Aflare Superior direct (SE TOT APELEAZA in functia complexa PANA CAND SE AJUNGE LA cineva care nu are superior direct)
--Procedura inserare coduri plutoane in vector;
--Procedura inserare date in tabelul detalii_plutoane care isi creeaza un tabel local de tipul "detalii_soldati"
--Functie Complexa Aflare superior maxim al unui soldat dat dupa Id care sa fie in acelasi pluton
--cu el si sa se afiseze cate medalii a castigat si insereaza intr-un tabel rezultatele
CREATE OR REPLACE PACKAGE pachet_complex AS
  TYPE pereche_rezultat is record
                         (cod_soldat soldat.cod_soldat%type, 
                         nume_soldat soldat.nume%type,
                         prenume_soldat soldat.prenume%type,
                         cod_superior soldat.cod_soldat%type, 
                         nume_superior soldat.nume%type,
                         prenume_superior soldat.prenume%type);
  TYPE rezultate_cmms IS TABLE OF pereche_rezultat;
  rezultate rezultate_cmms:= rezultate_cmms();
  TYPE date_importante_soldat is record
                         (cod_soldat soldat.cod_soldat%type, 
                         nume_soldat soldat.nume%type,
                         prenume_soldat soldat.prenume%type,
                         cod_superior soldat.cod_soldat%type, 
                         numar_medalii NUMBER);
  TYPE detalii_soldati IS TABLE OF date_importante_soldat INDEX BY PLS_INTEGER;
  TYPE detalii_pluton IS record
                         (cod_pluton pluton.cod_pluton%type,
                         soldati detalii_soldati);
  TYPE tabel_detalii_plutoane IS TABLE OF detalii_pluton INDEX BY PLS_INTEGER;
  detalii_plutoane tabel_detalii_plutoane;
  TYPE cod_plut IS TABLE OF NUMBER;
  coduri_plutoane cod_plut :=cod_plut();
  PROCEDURE inserare_coduri_plut;
  PROCEDURE inserare_det_plutoane;
  FUNCTION aflare_pluton(id_soldat soldat.cod_soldat%type) RETURN NUMBER;
  FUNCTION aflare_numar_medalii(id_soldat soldat.cod_soldat%type) RETURN NUMBER;
  FUNCTION aflare_superior_direct(id_soldat soldat.cod_soldat%type) RETURN NUMBER;
  FUNCTION aflare_superior_max(id_soldat soldat.cod_soldat%type) RETURN NUMBER;
END pachet_complex;
/
CREATE OR REPLACE PACKAGE BODY pachet_complex AS
  PROCEDURE inserare_coduri_plut
  IS
  BEGIN
    select cod_pluton
    bulk collect into coduri_plutoane
    from pluton;
  END inserare_coduri_plut;
  
  PROCEDURE inserare_det_plutoane
  IS
    det_sold detalii_soldati;
    dat_imp_sold date_importante_soldat;
    nr_sold_din_plut number(3);
  BEGIN
    for i in coduri_plutoane.first..coduri_plutoane.last loop
        select s.cod_soldat, s.nume, s.prenume, s.cod_superior_direct, aflare_numar_medalii(s.cod_soldat)
        bulk collect into det_sold
        from soldat s
        where cod_pluton = coduri_plutoane(i);
        detalii_plutoane(i).cod_pluton := coduri_plutoane(i);
        detalii_plutoane(i).soldati := det_sold;
    end loop;
  END inserare_det_plutoane;
  
  FUNCTION aflare_pluton(id_soldat soldat.cod_soldat%type) 
  RETURN NUMBER
  IS 
    rezultat NUMBER(2);
  BEGIN
    select cod_pluton
    into rezultat
    from soldat s
    where id_soldat = s.cod_soldat;
    return rezultat;
  EXCEPTION
    WHEN NO_DATA_FOUND then
    RAISE_APPLICATION_ERROR(-20000, 'Nu exista soldatul dat');
    WHEN OTHERS then
    RAISE_APPLICATION_ERROR(-20001, 'Alta eroare');
  END aflare_pluton;
  
  FUNCTION aflare_numar_medalii(id_soldat soldat.cod_soldat%type) 
  RETURN NUMBER
  IS
    rezultat NUMBER(2);
  BEGIN
    select count(*)
    into rezultat
    from a_fost_decorat_cu 
    where cod_soldat=id_soldat;
    return rezultat;
  END aflare_numar_medalii;
  
  FUNCTION aflare_superior_direct(id_soldat soldat.cod_soldat%type) 
  RETURN NUMBER
  IS
    rezultat NUMBER(3);
  BEGIN
    select cod_superior_direct
    into rezultat
    from soldat
    where cod_soldat=id_soldat;
    return rezultat;
  END aflare_superior_direct;
  
  FUNCTION aflare_superior_max(id_soldat soldat.cod_soldat%type) 
  RETURN NUMBER
  IS
    de_inserat pereche_rezultat;
    soldat_curent NUMBER(3);
    pluton_curent NUMBER(2);
    superior NUMBER(3);
    ok NUMBER(1);
    numar_medalii NUMBER(2);
  BEGIN
    select cod_soldat, nume, prenume
    into de_inserat.cod_soldat, de_inserat.nume_soldat, de_inserat.prenume_soldat
    from soldat
    where cod_soldat = id_soldat;
    de_inserat.cod_superior:=de_inserat.cod_soldat;
    de_inserat.nume_superior:=de_inserat.nume_soldat;
    de_inserat.prenume_superior:=de_inserat.prenume_soldat;
    ok:=1;
    
    soldat_curent := id_soldat;
    pluton_curent := aflare_pluton(id_soldat);
    for i in detalii_plutoane.first..detalii_plutoane.last loop
      if detalii_plutoane(i).cod_pluton = pluton_curent then
        while ok=1 loop
          ok:=0;
          superior:=aflare_superior_direct(soldat_curent);
          for j in detalii_plutoane(i).soldati.first..detalii_plutoane(i).soldati.last loop
            if detalii_plutoane(i).soldati(j).cod_soldat = superior then
              ok:=1;
              soldat_curent := superior;
              de_inserat.cod_superior:=detalii_plutoane(i).soldati(j).cod_soldat;
              de_inserat.nume_superior:=detalii_plutoane(i).soldati(j).nume_soldat;
              de_inserat.prenume_superior:=detalii_plutoane(i).soldati(j).prenume_soldat;
              numar_medalii:=detalii_plutoane(i).soldati(j).numar_medalii;
            end if;
          end loop;
        end loop;
      end if;
    end loop;
    DBMS_OUTPUT.PUT_LINE(numar_medalii);
    return soldat_curent;
  END aflare_superior_max;
END pachet_complex;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE(pachet_complex.aflare_pluton(15));
  pachet_complex.inserare_coduri_plut;
  pachet_complex.inserare_det_plutoane;
  DBMS_OUTPUT.PUT_LINE(pachet_complex.coduri_plutoane(5));
  DBMS_OUTPUT.PUT_LINE(pachet_complex.aflare_numar_medalii(33));
  DBMS_OUTPUT.PUT_LINE(pachet_complex.aflare_superior_direct(41));
  DBMS_OUTPUT.PUT_LINE(pachet_complex.detalii_plutoane(1).soldati(4).nume_soldat);
  DBMS_OUTPUT.PUT_LINE(pachet_complex.aflare_superior_max(30));
END;
/