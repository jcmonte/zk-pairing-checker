// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pairing {
    struct G1Point {
        uint256 x;
        uint256 y;
    }

    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    G1Point public G1 = G1Point(1, 2);
    uint256 curve_order =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    
    function ecAdd(
        G1Point memory p1,
        G1Point memory p2
    ) public view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        (bool ok, bytes memory result) = address(6).staticcall(abi.encode(input));
        require(ok, "ec-add-failed");
        (r.x, r.y) = abi.decode(result, (uint256, uint256));
    }

    function ecMul(
        G1Point memory p,
        uint256 s
    ) public view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        (bool ok, bytes memory result) = address(7).staticcall(abi.encode(input));
        require(ok, "ec-mul-failed");
        (r.x, r.y) = abi.decode(result, (uint256, uint256));
    }

    /* @return The result of computing the pairing check
   *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
   *         For example,
   *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
   */
    function identityPairing() public view returns (bool) {
        uint256[12] memory input;
        // note input ordering is out of order
        input[0] = 1368015179489954701390400359078579693043519447331113978918064868415326638035;
        input[1] = 9918110051302171585080402603319702774565515993150576347155970296011118125764;
        input[3] = 18946911109089220417246882279344009185046244062048267838251074785636587881882; // x1
        input[2] = 17937209039640432698657489930665601306227050938840470801941878726927091573255; // x2
        input[5] = 7532430684487998364299773373743645376429834191630786809785815495450660596027; // y1
        input[4] = 13393908504037547765226354946599244623109994250574185355684102800893342919379; // y2
        input[6] = 1368015179489954701390400359078579693043519447331113978918064868415326638035; 
        input[7] = 11970132820537103637166003141937572314130795164147247315533067598634108082819;
        input[9] = 18946911109089220417246882279344009185046244062048267838251074785636587881882; // x1
        input[8] = 17937209039640432698657489930665601306227050938840470801941878726927091573255; // x2
        input[11] = 7532430684487998364299773373743645376429834191630786809785815495450660596027; // y1
        input[10] = 13393908504037547765226354946599244623109994250574185355684102800893342919379; // y2

        (bool ok, bytes memory result) = address(8).staticcall(abi.encode(input));
        require(ok, "simple-pairing-failed");
        return abi.decode(result, (bool));
    }

    function simplePairing(
        G1Point memory A,
        G2Point memory B,
        G1Point memory W,
        G2Point memory V
    ) public view returns (bool) {
        uint256[12] memory input;
        input[0] = A.x;
        input[1] = A.y;
        input[2] = B.X[1];
        input[3] = B.X[0];
        input[4] = B.Y[1];
        input[5] = B.Y[0];
        input[6] = W.x;
        input[7] = W.y;
        input[8] = V.X[1];
        input[9] = V.X[0];
        input[10] = V.Y[1];
        input[11] = V.Y[0];
        (bool ok, bytes memory result) = address(8).staticcall(abi.encode(input));
        require(ok, "simple-pairing-failed");
        return abi.decode(result, (bool));
    }

    // 0 = -A_1B_2 +\alpha_1\beta_2 + X_1\gamma_2 + C_1\delta_2\\X_1=x_1G1 + x_2G1 + x_3G1
    function pairing(
        G1Point memory A,
        G2Point memory B,
        G1Point memory C,
        uint256 x1,
        uint256 x2,
        uint256 x3
    ) public view returns (bool) {
        G1Point memory alpha = G1Point({
            x: 10744596414106452074759370245733544594153395043370666422502510773307029471145,
            y: 848677436511517736191562425154572367705380862894644942948681172815252343932
        });
        G2Point memory beta = G2Point({
            X: [10191129150170504690859455063377241352678147020731325090942140630855943625622, 12345624066896925082600651626583520268054356403303305150512393106955803260718],
            Y: [16727484375212017249697795760885267597317766655549468217180521378213906474374, 13790151551682513054696583104432356791070435696840691503641536676885931241944]
        });

        G1Point memory X = ecAdd(ecAdd(ecMul(G1, x1), ecMul(G1, x2)), ecMul(G1, x3));
        G2Point memory yotta = G2Point({
            X: [14502447760486387799059318541209757040844770937862468921929310682431317530875, 2443430939986969712743682923434644543094899517010817087050769422599268135103],
            Y: [11721331165636005533649329538372312212753336165656329339895621434122061690013, 4704672529862198727079301732358554332963871698433558481208245291096060730807]
        });

        G2Point memory sigma = G2Point({
            X: [6584456886510528562221720296624431746328412524156386210384049614268366928061, 13505823173380835868587575884635704883599421098297400455389802021584825778173],
            Y: [5101591763860554569577488373372350852473588323930260132008193335489992486594, 17537837094362477976396927178636162167615173290927363003743794104386247847571]
        });

        G1Point[4] memory p1 = [A, alpha, X, C];
        G2Point[4] memory p2 = [B, beta, yotta, sigma];

        uint256[24] memory input;
        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].x;
            input[j + 1] = p1[i].y;
            input[j + 2] = p2[i].X[1];
            input[j + 3] = p2[i].X[0];
            input[j + 4] = p2[i].Y[1];
            input[j + 5] = p2[i].Y[0];
        }

        (bool ok, bytes memory result) = address(8).staticcall(abi.encode(input));
        require(ok, "pairing-failed");
        return abi.decode(result, (bool));
    }
}