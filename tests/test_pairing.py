import pytest
from ape import project
from py_ecc.bn128 import G1, G2, add, multiply, pairing, eq, neg, final_exponentiate, FQ12

# SETUP PHASE
# NOTE: More on fixtures is discussed in later sections of this guide!
@pytest.fixture(scope="session")
def owner(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def c(owner, project):
    return owner.deploy(project.Pairing)

def g1Tuple(p): # convert big point to string typle
    return (str(p[0]), str(p[1]))

def g2Tuple(p): # convert big point to string typle
    return ([str(p[0].coeffs[0]), str(p[0].coeffs[1])], [str(p[1].coeffs[0]), str(p[1].coeffs[1])])

def test_add():
    assert 1 + 1 == 2

def test_ecAdd(c):
    assert c.ecAdd((1, 2), (1, 2)) == add(G1, G1)

def test_ecMul(c):
    assert c.ecMul((1, 2), 2) == multiply(G1, 2)

def test_identity_pairing(c):
    P = multiply(G1, 2)
    Q = multiply(G2, 16)

    assert eq(pairing(Q, P), pairing(Q, P)) # sanity check
    assert final_exponentiate(pairing(Q, P) * pairing(Q, neg(P))) == FQ12([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    assert c.identityPairing()

def test_simplePairing(c):
    P = multiply(G1, 2)
    Q = multiply(G2, 16)
    W = multiply(G1, 4)
    V = multiply(G2, 8)

    #print(g2Tuple(Q))
    
    assert eq(pairing(Q, P), pairing(V, W)) # sanity check

    assert final_exponentiate(pairing(Q, P) * pairing(V, neg(W))) == FQ12([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

    assert final_exponentiate(pairing(Q, P) * pairing(neg(V), W)) == FQ12([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

    assert c.simplePairing(g1Tuple(P), g2Tuple(Q), g1Tuple(neg(W)), g2Tuple(V))

def test_pairing(c):
    A = multiply(G1, 10)
    B = multiply(G2, 10)
    alpha = multiply(G1, 5)
    beta = multiply(G2, 6)
    X = multiply(G1, 3)
    yotta = multiply(G2, 10)
    C = multiply(G1, 2)
    sigma = multiply(G2, 20)

    assert final_exponentiate(pairing(B, neg(A)) * pairing(beta, alpha) * pairing(yotta, X) * pairing(sigma, C)) == FQ12([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    assert c.pairing(g1Tuple(neg(A)), g2Tuple(B), g1Tuple(C), 1, 1, 1)
