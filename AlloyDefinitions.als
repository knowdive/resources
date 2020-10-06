abstract sig Resource {} 

sig Property extends Resource 
 {sub_val: Resource -> Resource}

sig Class extends Resource {instances: set Resource}

// List Definition
sig List {} 
sig NonEmptyList extends List {next: List, element: Resource} 
fact Canonical { 
	no disj p0, p1: List | p0.next = p1.next and p0.element = p1.element 
} 
fun List::first (): Resource {this.element} 
fun List::rest (): List {this.next} 
fun List::addFront (e: Resource): List { 
	{p: List | p.next = this and p.element = e} 
}

// OWL/RDFS Definitions 
pred subClassOf[csup, csub: Class]
 {csub.instances in csup.instances}

pred disjointWith [c1, c2: Class] {no c1.instances & c2.instances}

pred allValuesFrom 
 [p: Property, c1: Class, c2: Class] 
 {all r1, r2: Resource | 
 r1 in c1.instances => 
 r2 in r1.(p.sub_val) => 
 r2 in c2.instances}

pred hasValue [p: Property, c1: Class, r: Resource] 
 {all r1: Resource | r1 in c1.instances => r1.(p.sub_val) = r}

pred maxCardinality [p: Property, c1: Class, N: Int]
 {all r1: Resource| r1 in c1.instances <=> 
 # r1.(p.sub_val) <= int N }

pred intersectionOf [clist: List, c1: Class] 
 {all r: Resource| r in c1.instances <=> 
 all ca: clist.*next.val | r in ca.instances}

pred unionOf [clist: List, c1: Class] 
 {all r: Resource| r in c1.instances <=> 
 some ca: clist.*next.val| r in ca.instances}

pred subPropertyOf [psup, psub: Property] 
 {psub.sub_val in psup.sub_val}

pred domain [p: Property, c: Class] 
 {(p.sub_val).Resource in c.instances}

pred inverseOf [p1, p2: Property] {p1.sub_val = ~(p2.sub_val)} 
