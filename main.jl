#parammetres
taillePop = 350
lBit = 22
probaCrossover =  1.0
probaMutation = 0.60
nGeneration = 50

#structures parametrique pour NSGA
type individu{X,Y}
    x::X
    y::Array{Y}

    individu{X,Y}(x,y) where{X,Y} = new(x,y)
    individu{X,Y}(ind::individu{X,Y}) where{X,Y} = new(copy(ind.x),copy(ind.y))
end

#petites fonctions utile pour le tri avant le crowding
function corespondVect(pop::Array{individu{X,Y},1}) where {X,Y}
	return function(ind::Int)
		return pop[ind].y	
	end
end
function lex(y1::Array{Y}, y2::Array{Y}) where {Y}
	i = 1
	while (i <= size(y1)[1]) && (y1[i] == y2[i])
		i += 1
	end
	
	if i > size(y1)[1]
		return true
	else
		return y1[i] < y2[i]
	end
end

#structures et fonctions spécifique à notre problème (le demonstrateur de VEGA du cours)
type pointReel
	bx::Array{Bool}
	x::Float
	by::Array{Bool}
	y::Float
	lBit::Int

	pointReel(lBit) = new(Array{Bool}(lBit),0.0,Array{Bool}(lBit),0.0, lBit)
end

function schaffer(p::pointReel)
	calcVal(p)
	return ( (p.x)^2 , (p.x -2)^2)
end

#calcule la veleur du point pour le range [-5,5]
function calcVal(p::pointReel)
	p.x = sum(p.bx[p.lBit - i] * 2^i for i = 0:(p.lBit -1) ) * (10/(2^(p.lBit) -1)) -5
	p.y = sum(p.by[p.lBit - i] * 2^i for i = 0:(p.lBit -1) ) * (10/(2^(p.lBit) -1)) -5
end

function generePoint(p::pointReel)
	p.x = rand(Bool, p.lBit)
	p.y = rand(Bool, p.lBit)

	calcVal(p)
end

#crossover masque
function crossoverPoint(p1::pointReel, p2::pointReel)
	enfant1 = pointReel(p1.lBit)
	enfant2 = pointReel(p1.lBit)

	for i = 1:lBit
		if rand(Bool, 1)[1]
			enfant1.bx[i] = p1.bx[i]
			enfant1.by[i] = p1.by[i]

			enfant2.bx[i] = p2.bx[i]
			enfant2.by[i] = p2.by[i]
		else
			enfant2.bx[i] = p1.bx[i]
			enfant2.by[i] = p1.by[i]

			enfant1.bx[i] = p2.bx[i]
			enfant1.by[i] = p2.by[i]
		end
	end

	calcVal(enfant1)
	calcVal(enfant2)

	return (enfant1, enfant2)
end

#swap de 1 bit sur x et 1 bit sur y
function mutationPoint(p::pointReel)
	ind = rand(Int, 1)[1]
	p.bx[ind] = ! p.bx[ind]

	ind = rand(Int, 1)[1]
	p.by[ind] = ! p.by[ind]
end

include("archive.jl")
include("ranking.jl")

function NSGA2(taillePop::Int, probaCrossover::Float, probaMutation::Float, nGeneration::Int, pop::Array{individu{X,Y},1}, crossover, mutation, evaluation, domine, genere) where {X,Y}
	#generation de la population initiale
	for i = 1:taillePop
		push!(pop, pointReel(lBit))
		genere(pop[i])
	end

	#coeur
	for gen = 1:nGeneration

		#classement par rang pour la nouvelle generation
		F = ranking(pop, domine)
		taillePop = max(taillePop, size(F[1])[1]) #on agrandit la pop si besoin pour garder tous les points efficaces
		updatepop(F, pop, taillePop)
		
		for i = 1:size(F)[1]
			sort!(F[i], lt=lex, by=corespondVect(pop))
		end

	end

	#fin
	return taillePop
end

#calculs
pop = Array{individu{pointReel,Float},1}()
taillePop = NSGA2(taillePop, probaCrossover, probaMutation, nGeneration, pop, crossoverPoint, mutationPoint, schaffer, domineMin, generePoint)

#traitement et affichage des résultats
l = listeND{pointReel,Float}(domineMin, dominefaibleMin)
for i = 1:taillePop
	push!(l, pop[i])
end
println("front de pareto : ", retour(l))

#=
l = listeND{Int32,Int32}(domineMin, dominefaibleMin)
pop = Array{individu{Int32,Int32},1}()

ind = individu{Int32,Int32}(1,[5,5])
ind2 = individu{Int32,Int32}(2,[4,6])
ind3 = individu{Int32,Int32}(3,[6,6])

push!(l,ind)
push!(l,ind2)
push!(l,ind3)

push!(pop,ind)
push!(pop,ind2)
push!(pop,ind3)

F = ranking( pop, domineMin)

println("pop : ",pop)
println("l : ",l)
println("F : ",F)
println("indrang : ", indrang(F,pop))
println("newpop : ",updatepop(F , pop, 2))
=#
