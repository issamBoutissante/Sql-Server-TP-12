-- Candidat(CodeCand,NomCand,DateInscription,#NumSession,NomSociete)
-- Session(NumSession,DatDebutSession,DateFinSession,NomStage)
-- Module(CodeMod,NomMod,MasseHoraire,NomFormateur)
-- Enseigne(#CodeMod,NomFormateur,#NumSession)
-- Notes(#CodeCand , #CodeMod , Note)



-- i already have the tables and i just need to add Notes table
use database FormCont
go
create Table Notes(
codeCand int,
codeMod int,
note decimal,
constraint fk_codeCand_Candidat foreign key(codeCand) references Candidat(codeCand),
constraint fk_codeMod_Module foreign key(codeMod) references Module(codeMod)
)

-- 2-	Cr�er la proc�dure stock�e qui retourne dans un param�tre de sortie
-- le nombre de candidats ayants suivi un stage comme argument.
create proc sp_getNombreCandidat(@numSession int,@nbCond int output)
as
begin
   select @nbCond=count(*) from Candidat where numSession=@numSession
end

--  test
declare @nbCondidat int
exec sp_getNombreCandidat 2,@nbCondidat output
print @nbCondidat
-- 3-	Cr�er un d�clencheur qui refuse de diminuer la masse horaire pr�vue d�un module. .
create trigger tr_Module_forUpdate
on Module
for Update
as
begin
   if(Update(MasseHoraire))
    begin
	   declare @OldMassHoraire int
	   declare @NewMassHoraire int
	   select @OldMassHoraire=masseHoraire from deleted
	   select @NewMassHoraire=masseHoraire from inserted
	   if(@NewMassHoraire<@OldMassHoraire)
	     begin
		   RaisError('vous peuvez pas diminuer la masse horaire',16,1)
		   rollback
		 end
	end
end
select * from Module
Update Module set masseHoraire=20 where codeMod=1

-- 4-	Cr�er la proc�dure stock�e qui re�oit en param�tre le nom de stage et 
-- permet de r�cup�rer la liste des sessions du stage concern� non encore r�alis�.
create proc sp_getListeSessionNonRealise(@nomStage varchar(15))
as
begin
  select * from [Session]
  where NomStage=@nomStage and dateDebutSession<GETDATE()
end
select * from Session
exec sp_getListeSessionNonRealise nomStage1

--5-	Cr�er un d�clencheur qui refuse d�affecter le m�me formateur pour enseigner dans deux modules diff�rents.
create trigger tr_Module_forInsert
on Module
for Insert
as
begin
  Declare @NbFormateur int
  select @NbFormateur=count(*) from Module join inserted
  on Module.nomFormateur =inserted.nomFormateur
  if(@NbFormateur>1)
  begin
    print 'ce formateur deja existe'
	rollback
  end
end

insert into Module values(4,'WCC',20,'Aginane')
select * from Module

-- 6-	Cr�er la proc�dure stock�e permettant de retourner tous les modules enseign�s dans 
-- des sessions, stock�s dans la base au cours d�une p�riode donn�e en param�tre 
-- (deux dates d1 et d2 qui correspondent aux dates de d�but de session).

create proc sp_getModulesEnseignes(@d1 date,@d2 date)
as 
begin
  select Module.* from Enseigne join [Session] on Enseigne.numSession=[Session].numSession
  join Module on Enseigne.codeMod=Module.codeMod
  where dateDebutSession>= @d1 and dateFinSession<=@d2
end
declare @date1 date
set @date1=dateadd(Year,-1,getdate())
declare @date2 date
set @date2=dateadd(MONTH,1,getdate())
exec sp_getModulesEnseignes @date1,@date2

-- 7-	Cr�er une proc�dure stock�e qui affiche la liste des notes 
-- des candidats pour chaque module (CodeCand, CodeMod1, CodeMod2,�) 
select * from Notes
select * from Candidat
select * from Module
create proc sp_getListNote
as
begin
  select * from Notes join Candidat on Notes.codeCand=Candidat.codeCand
  join Module on Notes.codeMod=Module.codeMod
  
end

select codeCand,PFF,Mobile,WCS
from(
   select C.codeCand,nomMod,note from Notes N join Candidat C on N.codeCand=C.codeCand
   join Module M on N.codeMod=M.codeMod
) as ResultTable
Pivot(
  sum(note)
  for nomMod in (PFF,Mobile,WCS)
) as PivotTable
