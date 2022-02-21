

  -- procédure de chargement des lignes Compteur
  declare cur_cpt cursor for select pce, pose_cpt, depose_cpt, matricule_cpt, index_pose_cpt
                         from compteur;
		  rec_cpt record;
		  cur_date cursor for select distinct(date_e) as date_e from date_intermediaire order by date_e;
		  rec_date record;
		  date_deb timestamp;
	begin					 
		-- Réinitialisation de la table avant l'éxécution
		truncate histo_compteur_L;
		open cur_cpt;
		loop
			fetch cur_cpt into rec_cpt;
			exit when not found;
            --On garde toutes la selection dans une table
			insert into date_intermediaire
			-- recherche des évènements sur les enregistreus dans la plage de date du compteur
			select pose_enreg as date_e 
			from histo_enregistreur where pose_enreg between rec_cpt.pose_cpt and rec_cpt.depose_cpt and pce = rec_cpt.pce
			union
			select depose_enreg as date_e 
			from histo_enregistreur where depose_enreg between rec_cpt.pose_cpt and rec_cpt.depose_cpt and pce = rec_cpt.pce
				UNION
			-- recherche des évènements sur les histo_convertisseurs dans la plage de date du compteur
			select pose_conv as date_e 
			from histo_convertisseur where pose_conv between rec_cpt.pose_cpt and rec_cpt.depose_cpt and pce = rec_cpt.pce
			union
			select depose_conv as date_e 
			from histo_convertisseur where depose_conv between rec_cpt.pose_cpt and rec_cpt.depose_cpt and pce = rec_cpt.pce;
			
			
			-- Parcour de la table des dates intermédiaires pour découper éventuellement la ligne de compteur sur laquelle on pointe
			open cur_date;
			date_deb := rec_cpt.pose_cpt;
			loop
				fetch cur_date into rec_date;
				exit when not found;
				insert into histo_compteur_L(pce, pose_cpt, depose_cpt, matricule_cpt, index_pose_cpt)
				values(rec_cpt.pce, date_deb, rec_date.date_e, rec_cpt.matricule_cpt, rec_cpt.index_pose_cpt);
				-- On positionne la prochaine date_deb à la date fin de la lgne précédente
				date_deb := rec_date.date_e;
			end loop;
			close cur_date;
			truncate date_intermediaire;
			-- On insert le dernier bloc de ligne où la seule ligne sur laquelle on pointe si elle n'a pas été découpée
			insert into histo_compteur_L(pce, pose_cpt, depose_cpt, matricule_cpt, index_pose_cpt)
			values(rec_cpt.pce, date_deb, rec_cpt.depose_cpt, rec_cpt.matricule_cpt, rec_cpt.index_pose_cpt);
		end loop;
		close cur_cpt;
	end;