##################################################################################################
# Script d'extraction des moyennes de f1 et f2, de la durée, du temps de début, du temps de fin, #
# et du label d'un phone dans une tier donnée                                                    #
# A partir du wav et du textgrid sélectionnés dans la fenêtre principale de Praat                #
#                                                                                                #
# Auteure : Mélanie Lancien, Unil section SLI, Juin 2019, pour l'école d'été PFC                 #
##################################################################################################

##Avant de lancer le script, un wav et son textgrid doivent être sélectionnés dans la fenêtre principale de Praat
##Dire au script que l'on va utiliser le son et le textgrid selectionnés dans la fenêtre Praat
sonSelectionne$ = selected$("Sound")
textGridSelectionne$ = selected$("TextGrid")
##Selectionner la tier qui contient l'alignement en phones (Modifier le chiffre en fonction de la tier à considérer)
tier= 5

##Créer le fchier de résultats ---> modifier le chemin d'accès ainsi que le nom du fichier de sortie
fichierSortie$ = "C:\Users\Melan\Desktop\ecole_ete\ficher_acoustique.txt"
writeFile: fichierSortie$, "Fichier", tab$, "TempsDebut",tab$, "TempsFin",tab$,"Phoneme",tab$, "Duree(secondes)", tab$, "MoyenneF1(Hz)",tab$, "MoyenneF2(Hz)", newline$


##Selectionner le son et le textgrid, calculer le nombre total d'intervalles dans la tier, et créer un fichier 'formants' pour cette tier
select TextGrid 'textGridSelectionne$'
nbIntervalles = Get number of intervals: tier
select Sound 'sonSelectionne$'
fichierFormants =To Formant (burg): 0, 5, 5000, 0.025, 50

##Mécanisme d'extraction des valeurs
#Pour chaque intervalle de la tier désignée plus haut
for iIntervalle from 1 to nbIntervalles
    #Extraire le label du phone contenu dans l'intervalle
    select TextGrid 'textGridSelectionne$'
    phoneme$ = Get label of interval: tier, iIntervalle
		#Si l'intervalle n'est pas vide
		if phoneme$ !=""
  		#Obtenir le temps de début du phone, son temps de fin, et calculer sa durée
    		debut = Get start point: tier, iIntervalle
    		fin = Get end point: tier, iIntervalle
    		duree = fin - debut
    		milieu = debut + duree/2
    		#Obtenir les valeurs moyennes des F1 et F2 en Hertz(possibilité de changer "Hertz" par "Bark")
    		select Formant 'sonSelectionne$'
    		f1 = Get mean: 1, debut, fin, "Hertz"
    		f2 = Get mean: 2, debut, fin, "Hertz"
		#Ecrire les éléments éxtraits dans le fichier de résultat créé au début
    		appendFileLine:fichierSortie$, sonSelectionne$, tab$, debut, tab$, fin, tab$, phoneme$, tab$, duree, tab$, f1,tab$, f2 
	endif 
endfor

#On efface le fichier formant qui ne sera plus utile
removeObject: fichierFormants 