// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {SignedMath} from "openzeppelin/contracts/utils/math/SignedMath.sol";
import {Base64} from "base64/base64.sol";

import {IFileStore, File} from "./interfaces/IFileStore.sol";
import {IGfxModule} from "./interfaces/IGfxModule.sol";
import {ART0x1Types} from "./ART0x1Types.sol";

/// @author hashrunner.eth
/// @title  ART0x1Program (v1)
contract ART0x1Program is Ownable {
    //
    //  ██████╗ ██████╗  ██████╗  ██████╗ ██████╗  █████╗ ███╗   ███╗
    //  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝ ██╔══██╗██╔══██╗████╗ ████║
    //  ██████╔╝██████╔╝██║   ██║██║  ███╗██████╔╝███████║██╔████╔██║
    //  ██╔═══╝ ██╔══██╗██║   ██║██║   ██║██╔══██╗██╔══██║██║╚██╔╝██║
    //  ██║     ██║  ██║╚██████╔╝╚██████╔╝██║  ██║██║  ██║██║ ╚═╝ ██║
    //  ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  (v1)
    //

    // ------------------------------------------------------------------------
    // LIBRARIES
    // ------------------------------------------------------------------------

    using SignedMath for int16;

    // ------------------------------------------------------------------------
    // STORAGE
    // ------------------------------------------------------------------------

    IFileStore public fileStore =
        IFileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);

    string public description;

    // ------------------------------------------------------------------------
    // CONSTRUCTOR
    // ------------------------------------------------------------------------

    constructor() Ownable(msg.sender) {
        description = "ART0x1 is an Ethereum Runtime Art program and Solidity "
        "re-interpretation of ART1; a computer art program developed by "
        "Richard Williams in 1968 for the IBM 360 mainframe computer.";
    }

    // ------------------------------------------------------------------------
    // PROGRAM
    // ------------------------------------------------------------------------

    // RUN --------------------------------------------------------------------

    function runProgram(
        bytes[12] memory _instructions,
        ART0x1Types.TokenGfx memory _tokenGfx
    ) public view returns (string memory) {
        // Define 2x two-dimensional dynamic arrays
        bytes1[][] memory array1 = new bytes1[][](50);
        bytes1[][] memory array2 = new bytes1[][](50);

        // workaround two-dimensional array instantiation
        for (uint i = 0; i < 50; ) {
            array1[i] = new bytes1[](105);
            array2[i] = new bytes1[](105);
            unchecked {
                ++i;
            }
        }

        // Define title string
        string memory title;
        // initialize arrays based on first instruction set
        (array1, array2, title) = init(array1, array2, _instructions[0]);

        // define lookup table for sub programs
        function(bytes1[][] memory, bytes1[][] memory, bytes memory)
            view
            returns (bytes1[][] memory, bytes1[][] memory)[]
            memory subPrograms = new function(
                bytes1[][] memory,
                bytes1[][] memory,
                bytes memory
            ) view returns (bytes1[][] memory, bytes1[][] memory)[](6);

        subPrograms[0] = line;
        subPrograms[1] = solidRect;
        subPrograms[2] = openRect;
        subPrograms[3] = triangle;
        subPrograms[4] = ellipse;
        subPrograms[5] = quadrant;

        // iterate over remaining instruction strings and call subProgram fxns
        for (uint i = 1; i < _instructions.length; ) {
            if (_instructions[i].length == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }
            // convert ASCII digit to uint
            uint func = uint(uint8(_instructions[i][0])) - 48;

            bytes memory instr = new bytes(_instructions[i].length);
            for (uint j = 0; j < _instructions[i].length; ) {
                instr[j] = _instructions[i][j];
                unchecked {
                    ++j;
                }
            }

            // call figure function based on first digit of instruction string
            if (func < subPrograms.length) {
                (array1, array2) = subPrograms[func](array1, array2, instr);
            } else {
                revert("Invalid sub program: id does not exist.");
            }
            unchecked {
                ++i;
            }
        }

        return render(array1, array2, title, _tokenGfx);
    }

    // INIT -------------------------------------------------------------------

    function init(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    )
        internal
        pure
        returns (bytes1[][] memory, bytes1[][] memory, string memory)
    {
        ART0x1Types.InitInstructions memory initInstr = getInitInstr(
            _instructions
        );

        // Fill array1 and array2
        for (uint i = 0; i < 50; ) {
            for (uint j = 0; j < 105; ) {
                if (initInstr.nCol > 0 && j % initInstr.nCol == 0) {
                    _array1[i][j] = initInstr.sym1;
                } else {
                    _array1[i][j] = " ";
                }
                if (initInstr.mCol > 0 && j % initInstr.mCol == 0) {
                    _array2[i][j] = initInstr.sym2;
                } else {
                    _array2[i][j] = " ";
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2, initInstr.title);
    }

    // RENDER -----------------------------------------------------------------

    function render(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        string memory _title,
        ART0x1Types.TokenGfx memory _tokenGfx
    ) internal view returns (string memory) {
        string memory result = string(
            abi.encodePacked(
                renderHeaders(_tokenGfx),
                "<rect x='0' y='0' width='100%' height='100%' style='fill:",
                _tokenGfx.colors[0],
                "' />"
            )
        );

        string memory arr1RowChars;
        string memory arr2RowChars;

        string memory arr1Row;
        string memory arr2Row;

        uint yPos = 112;

        // Iterate through the arrays to create the SVG text elements
        for (uint i = 0; i < 50; ) {
            arr1RowChars = "";
            arr2RowChars = "";
            for (uint j = 0; j < 105; ) {
                arr1RowChars = string(
                    abi.encodePacked(arr1RowChars, _array1[i][j])
                );
                arr2RowChars = string(
                    abi.encodePacked(arr2RowChars, _array2[i][j])
                );
                unchecked {
                    ++j;
                }
            }

            // Add sym1 row to the SVG content
            arr1Row = string(
                abi.encodePacked(
                    '<text x="50%" y="',
                    uintToString(yPos),
                    '" xml:space="preserve"><![CDATA[',
                    arr1RowChars,
                    "]]></text>"
                )
            );
            result = string(abi.encodePacked(result, arr1Row));

            // Add sym2 row to the SVG content
            arr2Row = string(
                abi.encodePacked(
                    '<text x="50%" y="',
                    uintToString(yPos),
                    '" xml:space="preserve"><![CDATA[',
                    arr2RowChars,
                    "]]></text>"
                )
            );
            result = string(abi.encodePacked(result, arr2Row));

            // Add the title to the last row of the SVG
            if (i == 49) {
                result = string(
                    abi.encodePacked(
                        result,
                        '<text x="50%" y="',
                        uintToString(yPos + 36),
                        '" xml:space="preserve"><![CDATA[',
                        _title,
                        "]]></text>"
                    )
                );
            }

            yPos += 12; // Increment yPos by the height of each row

            unchecked {
                i++;
            }
        }

        return string(abi.encodePacked(result, "</svg>"));
    }

    // RENDER UTILS -----------------------------------------------------------

    function renderHeaders(
        ART0x1Types.TokenGfx memory _tokenGfx
    ) internal view returns (string memory) {
        string memory openTags = string(
            abi.encodePacked(
                '<svg id="svg" version="2.0" encoding="utf-8" viewBox="0 0 109'
                '6 811" preserveAspectRatio="xMidYMid" xmlns="http://www.w3.or'
                'g/2000/svg"><style>'
            )
        );

        string memory injectedFont;
        if (bytes(_tokenGfx.fontFilename).length > 0) {
            File memory ethfsFile = fileStore.getFile(_tokenGfx.fontFilename);
            injectedFont = string(
                abi.encodePacked(
                    '@font-face{font-family: "',
                    _tokenGfx.fontName,
                    '";src:url(data:font/woff2;base64,',
                    ethfsFile.read(),
                    ')format("woff2");font-weight:normal;font-style:normal;}'
                )
            );
        }

        string memory styles = string(
            abi.encodePacked(
                "text{font:",
                _tokenGfx.fontSize,
                ' "',
                _tokenGfx.fontName,
                '",monospace;text-anchor:middle;user-select:none;-webkit-user-'
                "select:none;-moz-user-select:none;-ms-user-select:none;}text:"
                "nth-child(odd){fill:",
                _tokenGfx.colors[1],
                ";}text:nth-child(even){fill:",
                _tokenGfx.colors[2],
                ";}</style>"
            )
        );

        return string(abi.encodePacked(openTags, injectedFont, styles));
    }

    // ------------------------------------------------------------------------
    // SUB PROGRAMS
    // ------------------------------------------------------------------------

    // LINE -------------------------------------------------------------------

    function line(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ART0x1Types.ShapeInstructions memory lineInstr = getShapeInstr(
            _instructions
        );

        require(
            lineInstr.nC != 0 || lineInstr.nR != 0,
            "Invalid line: nC and nR cannot be zero."
        );

        uint16 maxRows = uint16(_array1.length);
        uint16 maxCols = uint16(_array1[0].length);

        drawLine(_array1, _array2, lineInstr, maxRows, maxCols);

        uint repeatRowsLength = lineInstr.repeatRows.length;
        for (uint i = 0; i < repeatRowsLength; ) {
            ART0x1Types.ShapeInstructions memory repeatedLineInstr = lineInstr;
            // override row / col vals with repeat vals
            repeatedLineInstr.row = lineInstr.repeatRows[i];
            repeatedLineInstr.col = lineInstr.repeatCols[i];

            drawLine(_array1, _array2, repeatedLineInstr, maxRows, maxCols);
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawLine(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        ART0x1Types.ShapeInstructions memory _instr,
        uint16 _maxRows,
        uint16 _maxCols
    ) internal pure {
        bytes1[][] memory targetArray = _instr.arr == 1 ? _array1 : _array2;

        if (_instr.nR == 1) {
            drawHorizontalLine(
                targetArray,
                _instr.row,
                _instr.col,
                _instr.nC,
                _instr.sym,
                _maxRows,
                _maxCols
            );
        } else if (_instr.nC == 1) {
            drawVerticalLine(
                targetArray,
                _instr.row,
                _instr.col,
                _instr.nR,
                _instr.sym,
                _maxRows,
                _maxCols
            );
        } else {
            drawDiagonalLine(targetArray, _instr, _maxRows, _maxCols);
        }
    }

    function drawHorizontalLine(
        bytes1[][] memory _array,
        int16 row,
        int16 col,
        int16 nC,
        bytes1 sym,
        uint16 _maxRows,
        uint16 _maxCols
    ) public pure {
        if (nC > 0) {
            // For positive nC, draw line rightward from the starting column
            for (int16 i = 0; i < nC; ++i) {
                int16 newCol = col + i;
                if (
                    row >= 0 &&
                    newCol >= 0 &&
                    uint16(row) < _maxRows &&
                    uint16(newCol) < _maxCols
                ) {
                    _array[uint16(row)][uint16(newCol)] = sym;
                }
            }
        } else {
            // For negative nC, draw line leftward, adjusting the loop to
            // include the start column
            for (int16 i = 0; i > nC; --i) {
                int16 newCol = col + i;
                if (
                    row >= 0 &&
                    newCol >= 0 &&
                    uint16(row) < _maxRows &&
                    uint16(newCol) < _maxCols
                ) {
                    _array[uint16(row)][uint16(newCol)] = sym;
                }
            }
        }
    }

    function drawVerticalLine(
        bytes1[][] memory _array,
        int16 row,
        int16 col,
        int16 nR,
        bytes1 sym,
        uint16 _maxRows,
        uint16 _maxCols
    ) internal pure {
        int16 startRow = row;
        int16 endRow = row + nR;

        // Adjust start and end for negative nR
        if (nR < 0) {
            startRow = row + nR + 1; // Start further up if nR is negative
            endRow = row + 1; // And end just above the initial row
        }

        for (int16 i = startRow; i < endRow; ++i) {
            if (
                i >= 0 &&
                col >= 0 &&
                uint16(i) < _maxRows &&
                uint16(col) < _maxCols
            ) {
                _array[uint16(i)][uint16(col)] = sym;
            }
        }
    }

    function drawDiagonalLine(
        bytes1[][] memory _array,
        ART0x1Types.ShapeInstructions memory lineInstr,
        uint16 _maxRows,
        uint16 _maxCols
    ) internal pure {
        // Define vars for Bresenham's line algorithm
        int16 endRow = int16(lineInstr.row) +
            (
                lineInstr.nR > 0
                    ? int16(lineInstr.nR) - 1
                    : int16(lineInstr.nR) + 1
            );
        int16 endCol = int16(lineInstr.col) +
            (
                lineInstr.nC > 0
                    ? int16(lineInstr.nC) - 1
                    : int16(lineInstr.nC) + 1
            );

        int16 currentRow = int16(lineInstr.row);
        int16 currentCol = int16(lineInstr.col);

        int16 stepRow = lineInstr.nR > 0 ? int16(1) : int16(-1);
        int16 stepCol = lineInstr.nC > 0 ? int16(1) : int16(-1);

        int16 err = (
            abs(lineInstr.nC) > abs(lineInstr.nR)
                ? abs(lineInstr.nC)
                : -abs(lineInstr.nR)
        ) / 2;
        int16 e2;

        // Execute Bresenham's line algorithm
        while (
            (stepRow > 0 ? currentRow <= endRow : currentRow >= endRow) ||
            (stepCol > 0 ? currentCol <= endCol : currentCol >= endCol)
        ) {
            if (
                currentRow >= 0 &&
                currentCol >= 0 &&
                uint16(currentRow) < _maxRows &&
                uint16(currentCol) < _maxCols
            ) {
                _array[uint16(currentRow)][uint16(currentCol)] = lineInstr.sym;
            }

            if (currentCol == endCol && currentRow == endRow) {
                break;
            }

            e2 = err;
            if (e2 > -abs(lineInstr.nC)) {
                err -= abs(lineInstr.nR);
                currentCol += stepCol;
            }
            if (e2 < abs(lineInstr.nR)) {
                err += abs(lineInstr.nC);
                currentRow += stepRow;
            }
        }
    }

    // SOLID RECTANGLE --------------------------------------------------------

    function solidRect(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ART0x1Types.ShapeInstructions memory rectInstr = getShapeInstr(
            _instructions
        );

        require(
            rectInstr.nC != 0 || rectInstr.nR != 0,
            "Invalid solid rectangle: nC and nR cannot be zero."
        );
        require(
            int16(rectInstr.row) >= 0,
            "Invalid solid rectangle: row must be greater than zero."
        );
        require(
            int16(rectInstr.col) >= 0,
            "Invalid solid rectangle: col must be greater than zero."
        );

        uint16 maxRows = uint16(_array1.length);
        uint16 maxCols = uint16(_array1[0].length);

        bytes1[][] memory targetArray = rectInstr.arr == 1 ? _array1 : _array2;

        drawSolidRect(
            targetArray,
            rectInstr.row,
            rectInstr.col,
            rectInstr,
            maxRows,
            maxCols
        );

        uint repeatRowsLength = rectInstr.repeatRows.length;
        for (uint i = 0; i < repeatRowsLength; ) {
            drawSolidRect(
                targetArray,
                rectInstr.repeatRows[i],
                rectInstr.repeatCols[i],
                rectInstr,
                maxRows,
                maxCols
            );
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawSolidRect(
        bytes1[][] memory _arr,
        int16 _row,
        int16 _col,
        ART0x1Types.ShapeInstructions memory rectInstr,
        uint16 _maxRows,
        uint16 _maxCols
    ) internal pure {
        for (int16 i = 0; i < rectInstr.nR; ) {
            int16 newRow = _row + i;
            drawHorizontalLine(
                _arr,
                newRow,
                _col,
                rectInstr.nC,
                rectInstr.sym,
                _maxRows,
                _maxCols
            );
            unchecked {
                ++i;
            }
        }
    }

    // OPEN RECTANGLE ---------------------------------------------------------

    function openRect(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ART0x1Types.ShapeInstructions memory rectInstr = getShapeInstr(
            _instructions
        );

        require(
            rectInstr.nC != 0 || rectInstr.nR != 0,
            "Invalid open rectangle: nC and nR cannot be zero."
        );
        require(
            int16(rectInstr.row) >= 0,
            "Invalid open rectangle: row must be greater than zero."
        );
        require(
            int16(rectInstr.col) >= 0,
            "Invalid open rectangle: col must be greater than zero."
        );

        uint16 maxRows = uint16(_array1.length);
        uint16 maxCols = uint16(_array1[0].length);

        bytes1[][] memory targetArray = rectInstr.arr == 1 ? _array1 : _array2;

        drawOpenRect(
            targetArray,
            rectInstr.row,
            rectInstr.col,
            rectInstr,
            maxRows,
            maxCols
        );

        uint repeatRowsLength = rectInstr.repeatRows.length;
        for (uint i = 0; i < repeatRowsLength; ) {
            drawOpenRect(
                targetArray,
                rectInstr.repeatRows[i],
                rectInstr.repeatCols[i],
                rectInstr,
                maxRows,
                maxCols
            );
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawOpenRect(
        bytes1[][] memory _arr,
        int16 _row,
        int16 _col,
        ART0x1Types.ShapeInstructions memory rectInstr,
        uint16 _maxRows,
        uint16 _maxCols
    ) internal pure {
        // Draw top and bottom horizontal lines
        for (int16 i = 0; i < rectInstr.nC; ) {
            int16 newCol = _col + i;
            if (_row >= 0) {
                drawHorizontalLine(
                    _arr,
                    _row,
                    newCol,
                    1,
                    rectInstr.sym,
                    _maxRows,
                    _maxCols
                );
            }
            if (_row + rectInstr.nR - 1 >= 0) {
                drawHorizontalLine(
                    _arr,
                    _row + rectInstr.nR - 1,
                    newCol,
                    1,
                    rectInstr.sym,
                    _maxRows,
                    _maxCols
                );
            }
            unchecked {
                ++i;
            }
        }

        // Draw left and right vertical lines
        for (int16 i = 1; i < rectInstr.nR - 1; ) {
            int16 newRow = _row + i;
            if (_col >= 0) {
                drawVerticalLine(
                    _arr,
                    newRow,
                    _col,
                    1,
                    rectInstr.sym,
                    _maxRows,
                    _maxCols
                );
            }
            if (_col + rectInstr.nC - 1 >= 0) {
                drawVerticalLine(
                    _arr,
                    newRow,
                    _col + rectInstr.nC - 1,
                    1,
                    rectInstr.sym,
                    _maxRows,
                    _maxCols
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    // TRIANGLE ---------------------------------------------------------------

    function triangle(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ART0x1Types.ShapeInstructions memory triInstr = getShapeInstr(
            _instructions
        );

        require(
            (triInstr.nR == 0 && triInstr.nC != 0) ||
                (triInstr.nR != 0 && triInstr.nC == 0),
            "Invalid triangle: either nR or nC must be zero."
        );

        // Determine which array to use
        bytes1[][] memory targetArray = triInstr.arr == 1 ? _array1 : _array2;

        // Draw the base triangle
        drawTriangle(
            targetArray,
            triInstr.row,
            triInstr.col,
            triInstr.nR,
            triInstr.nC,
            triInstr.sym
        );

        // Draw repeated triangles
        uint repeatRowsLength = triInstr.repeatRows.length;
        for (uint i = 0; i < repeatRowsLength; ) {
            drawTriangle(
                targetArray,
                triInstr.repeatRows[i],
                triInstr.repeatCols[i],
                triInstr.nR,
                triInstr.nC,
                triInstr.sym
            );
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawTriangle(
        bytes1[][] memory _array,
        int16 _row,
        int16 _col,
        int16 _nR,
        int16 _nC,
        bytes1 _sym
    ) internal pure {
        int16 absNR = _nR > 0 ? _nR : -_nR;
        int16 absNC = _nC > 0 ? _nC : -_nC;
        int16 arrayWidth = int16(uint16(_array[0].length));
        int16 arrayHeight = int16(uint16(_array.length));

        if (_nR != 0) {
            for (int16 i = 0; i < absNR; i++) {
                for (int16 j = -i; j <= i; ) {
                    int16 x = _col + j;
                    int16 y = _row + (_nR > 0 ? i : -i);
                    if (x >= 0 && y >= 0 && x < arrayWidth && y < arrayHeight) {
                        _array[uint16(y)][uint16(x)] = _sym;
                    }
                    unchecked {
                        ++j;
                    }
                }
            }
        } else if (_nC != 0) {
            for (int16 i = 0; i < absNC; i++) {
                for (int16 j = -i; j <= i; ) {
                    int16 x = _col + (_nC > 0 ? i : -i);
                    int16 y = _row + j;
                    if (x >= 0 && y >= 0 && x < arrayWidth && y < arrayHeight) {
                        _array[uint16(y)][uint16(x)] = _sym;
                    }
                    unchecked {
                        ++j;
                    }
                }
            }
        }
    }

    // ELLIPSE ----------------------------------------------------------------

    function ellipse(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        // Parse the shape instructions from the input bytes
        ART0x1Types.ShapeInstructions memory ellInstr = getShapeInstr(
            _instructions
        );

        // Determine which array to use based on the 'arr' attribute
        bytes1[][] memory targetArray = ellInstr.arr == 1 ? _array1 : _array2;

        // Draw the base ellipse
        drawEllipse(
            targetArray,
            ellInstr.row,
            ellInstr.col,
            ellInstr.nC,
            ellInstr.nR,
            ellInstr.sym
        );

        // Draw repeated ellipses if needed
        uint repeatRowsLength = ellInstr.repeatRows.length;
        for (uint i = 0; i < repeatRowsLength; ) {
            drawEllipse(
                targetArray,
                ellInstr.repeatRows[i],
                ellInstr.repeatCols[i],
                ellInstr.nC,
                ellInstr.nR,
                ellInstr.sym
            );
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawEllipse(
        bytes1[][] memory _array,
        int16 _rowCenter,
        int16 _colCenter,
        int16 _horizontalRadius,
        int16 _verticalRadius,
        bytes1 _sym
    ) internal pure {
        int256[10] memory eData; // Array to hold all necessary variables

        // Initialize variables for the ellipse
        eData[0] = 0; // x
        eData[1] = int256(_verticalRadius); // y
        eData[2] = int256(_horizontalRadius) * int256(_horizontalRadius); // a2
        eData[3] = int256(_verticalRadius) * int256(_verticalRadius); // b2
        eData[4] = 2 * eData[2]; // twoA2
        eData[5] = 2 * eData[3]; // twoB2
        eData[6] = eData[3] - eData[2] * eData[1] + (eData[2] / 4); // d1
        eData[8] = 0; // dx
        eData[9] = eData[4] * eData[1]; // dy

        // Region 1
        while (eData[8] < eData[9]) {
            drawEllipsePoints(
                _array,
                _rowCenter,
                _colCenter,
                int16(eData[0]),
                int16(eData[1]),
                _sym
            );
            if (eData[6] < 0) {
                // Next point is to the right
                eData[6] += eData[3] * ((2 * eData[0]) + 3);
                eData[8] += eData[5];
                eData[0] += 1;
            } else {
                // Next point is diagonally down and to the right
                eData[6] +=
                    eData[3] *
                    ((2 * eData[0]) + 3) +
                    eData[2] *
                    ((-2 * eData[1]) + 2);
                eData[8] += eData[5];
                eData[9] -= eData[4];
                eData[0] += 1;
                eData[1] -= 1;
            }
        }

        // Initialize d2 for Region 2
        eData[7] =
            (eData[3] * (eData[0] + 1) * (eData[0] + 1)) +
            (eData[2] * (eData[1] - 1) * (eData[1] - 1)) -
            (eData[2] * eData[3]);

        // Region 2
        while (eData[1] >= 0) {
            drawEllipsePoints(
                _array,
                _rowCenter,
                _colCenter,
                int16(eData[0]),
                int16(eData[1]),
                _sym
            );
            if (eData[7] > (eData[2] * (3 - eData[1]))) {
                // Next point is directly above
                eData[7] += eData[2] * ((-2 * eData[1]) + 4);
                eData[1] -= 1;
            } else {
                // Next point is diagonally up and to the right
                eData[7] +=
                    eData[3] *
                    (2 * eData[0] + 2) +
                    eData[2] *
                    ((-2 * eData[1]) + 3);
                eData[8] += eData[5];
                eData[0] += 1;
                eData[1] -= 1;
            }
        }

        fillEllipse(
            _array,
            _rowCenter,
            _colCenter,
            _horizontalRadius,
            _verticalRadius,
            _sym
        );
    }

    function drawEllipsePoints(
        bytes1[][] memory _array,
        int16 _rowCenter,
        int16 _colCenter,
        int16 _x,
        int16 _y,
        bytes1 _sym
    ) internal pure {
        int16 width = int16(uint16(_array[0].length));
        int16 height = int16(uint16(_array.length));

        int16[4] memory dx = [_x, -_x, _x, -_x];
        int16[4] memory dy = [_y, _y, -_y, -_y];

        for (uint i = 0; i < 4; i++) {
            int16 newX = _colCenter + dx[i];
            int16 newY = _rowCenter + dy[i];

            if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
                _array[uint16(newY)][uint16(newX)] = _sym;
            }
        }
    }

    function fillEllipse(
        bytes1[][] memory _array,
        int16 _rowCenter,
        int16 _colCenter,
        int16 _horizontalRadius,
        int16 _verticalRadius,
        bytes1 _sym
    ) internal pure {
        int16 minY = _rowCenter - _verticalRadius;
        int16 maxY = _rowCenter + _verticalRadius;
        int16 minX = _colCenter - _horizontalRadius;
        int16 maxX = _colCenter + _horizontalRadius;

        for (int16 y = minY; y <= maxY; y++) {
            for (int16 x = minX; x <= maxX; x++) {
                if (
                    isPointInEllipse(
                        x,
                        y,
                        _rowCenter,
                        _colCenter,
                        _horizontalRadius,
                        _verticalRadius
                    )
                ) {
                    if (
                        y >= 0 &&
                        uint16(y) < _array.length &&
                        x >= 0 &&
                        uint16(x) < _array[0].length
                    ) {
                        _array[uint16(y)][uint16(x)] = _sym;
                    }
                }
            }
        }
    }

    function isPointInEllipse(
        int16 x,
        int16 y,
        int16 _rowCenter,
        int16 _colCenter,
        int16 _horizontalRadius,
        int16 _verticalRadius
    ) internal pure returns (bool) {
        int256 dx = int256(x) - int256(_colCenter);
        int256 dy = int256(y) - int256(_rowCenter);
        int256 a2 = int256(_horizontalRadius) * int256(_horizontalRadius);
        int256 b2 = int256(_verticalRadius) * int256(_verticalRadius);

        return (dx * dx) * b2 + (dy * dy) * a2 <= a2 * b2;
    }

    // QUADRANT ---------------------------------------------------------------

    function quadrant(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        uint16 maxRows = uint16(_array1.length);
        uint16 maxCols = uint16(_array1[0].length);

        // Mirror the top-left quadrant
        for (uint16 i = 0; i < 25; ++i) {
            for (uint16 j = 0; j < 52; ++j) {
                // To top-right quadrant
                _array1[i][maxCols - j - 1] = _array1[i][j];
                _array2[i][maxCols - j - 1] = _array2[i][j];

                // To bottom-left quadrant
                _array1[maxRows - i - 1][j] = _array1[i][j];
                _array2[maxRows - i - 1][j] = _array2[i][j];

                // To bottom-right quadrant
                _array1[maxRows - i - 1][maxCols - j - 1] = _array1[i][j];
                _array2[maxRows - i - 1][maxCols - j - 1] = _array2[i][j];
            }
        }

        // Mirror middle column
        uint16 middleCol = 52;
        for (uint16 i = 0; i < maxRows / 2; ++i) {
            // Mirror from top to bottom
            _array1[maxRows - i - 1][middleCol] = _array1[i][middleCol];
            _array2[maxRows - i - 1][middleCol] = _array2[i][middleCol];
        }

        return (_array1, _array2);
    }

    // ------------------------------------------------------------------------
    // TOKEN DATA
    // ------------------------------------------------------------------------

    function tokenHTML(
        ART0x1Types.TokenCtx memory _tokenCtx
    ) external view returns (string memory) {
        string memory script;
        if (_tokenCtx.moduleAddress != address(0)) {
            (_tokenCtx.gfx, script) = IGfxModule(_tokenCtx.moduleAddress)
                .runGfxModule(
                    _tokenCtx.instructions,
                    _tokenCtx.prn,
                    _tokenCtx.moduleUint,
                    _tokenCtx.moduleString
                );
        }

        return
            string(
                abi.encodePacked(
                    '<!DOCTYPE html><html><head><meta charset="UTF-8"><style>h'
                    "tml,body,svg{margin:0;padding:0;height:100%;width:100%;ov"
                    "erflow:hidden;}@media screen and (max-device-width:480px)"
                    "{body{-webkit-text-size-adjust:100%;}}</style></head>",
                    runProgram(_tokenCtx.instructions, _tokenCtx.gfx),
                    "<script>",
                    script,
                    "</script>"
                    "</body></html>"
                )
            );
    }

    function tokenSVG(
        ART0x1Types.TokenCtx memory _tokenCtx
    ) external view returns (string memory) {
        if (_tokenCtx.moduleAddress != address(0)) {
            (_tokenCtx.gfx, ) = IGfxModule(_tokenCtx.moduleAddress)
                .runGfxModule(
                    _tokenCtx.instructions,
                    _tokenCtx.prn,
                    _tokenCtx.moduleUint,
                    _tokenCtx.moduleString
                );
        }

        return runProgram(_tokenCtx.instructions, _tokenCtx.gfx);
    }

    function tokenURI(
        ART0x1Types.TokenCtx memory _tokenCtx
    ) external view returns (string memory) {
        string memory tokenId = uintToString(_tokenCtx.id);

        string memory script;
        if (_tokenCtx.moduleAddress != address(0)) {
            (_tokenCtx.gfx, script) = IGfxModule(_tokenCtx.moduleAddress)
                .runGfxModule(
                    _tokenCtx.instructions,
                    _tokenCtx.prn,
                    _tokenCtx.moduleUint,
                    _tokenCtx.moduleString
                );
        }

        string memory svg = runProgram(_tokenCtx.instructions, _tokenCtx.gfx);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"id": "',
                        tokenId,
                        '", "name": "ART0x1 #',
                        tokenId,
                        '", "description": "',
                        description,
                        '", "attributes": ',
                        getAttributes(_tokenCtx),
                        ', "image": "data:image/svg+xml;base64,',
                        Base64.encode(abi.encodePacked(svg)),
                        '", "animation_url": "data:text/html;base64,',
                        Base64.encode(
                            abi.encodePacked(
                                '<!DOCTYPE html><html><head><meta charset="UTF'
                                '-8"><style>html,body,svg{margin:0;padding:0;h'
                                "eight:100%;width:100%;overflow:hidden;}@media"
                                " screen and (max-device-width:480px){body{-we"
                                "bkit-text-size-adjust:100%;}}</style></head>",
                                svg,
                                "<script>",
                                script,
                                "</script></body></html>"
                            )
                        ),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // TOKEN DATA UTILS -------------------------------------------------------

    function getAttributes(
        ART0x1Types.TokenCtx memory _tokenCtx
    ) private pure returns (string memory) {
        string memory mode = modeToString(_tokenCtx.mode);
        string memory attributes = string(
            abi.encodePacked('[{"trait_type": "Mode", "value": "', mode, '"}')
        );

        if (
            _tokenCtx.mode == ART0x1Types.Mode.ORIGINAL ||
            _tokenCtx.mode == ART0x1Types.Mode.GALLERY
        ) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    ', {"trait_type": "Artist", "value": "',
                    addressToString(_tokenCtx.artistAddress),
                    '"}'
                )
            );
        }

        if (_tokenCtx.mode == ART0x1Types.Mode.GALLERY) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    ', {"trait_type": "Gallery", "value": "',
                    _tokenCtx.galleryName,
                    '"}'
                )
            );
            attributes = string(
                abi.encodePacked(
                    attributes,
                    ', {"trait_type": "Curator", "value": "',
                    addressToString(_tokenCtx.galleryCurator),
                    '"}'
                )
            );
        }

        string memory gfxModuleValue = _tokenCtx.moduleAddress == address(0)
            ? "None"
            : _tokenCtx.moduleName;
        attributes = string(
            abi.encodePacked(
                attributes,
                ', {"trait_type": "GFX Module", "value": "',
                gfxModuleValue,
                '"}'
            )
        );

        if (keccak256(bytes(gfxModuleValue)) != keccak256(bytes("None"))) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    ', {"trait_type": "Module Author", "value": "',
                    addressToString(_tokenCtx.moduleAuthor),
                    '"}'
                )
            );
        }

        return string(abi.encodePacked(attributes, "]"));
    }

    function modeToString(
        ART0x1Types.Mode _mode
    ) private pure returns (string memory) {
        if (_mode == ART0x1Types.Mode.PRE_REVEAL) return "Pre-Reveal";
        if (_mode == ART0x1Types.Mode.GALLERY) return "Gallery";
        return "Original";
    }

    // ------------------------------------------------------------------------
    // PROGRAM UTILS
    // ------------------------------------------------------------------------

    function getInitInstr(
        bytes memory _instructions
    ) internal pure returns (ART0x1Types.InitInstructions memory parsed) {
        // Skip "sym1" and a whitespace
        uint currentIndex = 5;
        // Get sym1
        parsed.sym1 = _instructions[currentIndex++];
        // Skip a whitespace, "nCol" character and a white space
        currentIndex += 6;
        // Get nCol
        uint n = 0;
        while (
            currentIndex < _instructions.length &&
            uint8(_instructions[currentIndex]) >= 48 &&
            uint8(_instructions[currentIndex]) <= 57
        ) {
            n = n * 10 + uint(uint8(_instructions[currentIndex]) - 48);
            currentIndex++;
        }
        parsed.nCol = n;
        // Skip a whitespace, "sym2" and a whitspace
        currentIndex += 6;
        // Get sym2
        parsed.sym2 = _instructions[currentIndex++];
        // Skip a whitespace, "mCol" and a whitespace
        currentIndex += 6;
        // Get mCol
        uint m = 0;
        while (
            currentIndex < _instructions.length &&
            uint8(_instructions[currentIndex]) >= 48 &&
            uint8(_instructions[currentIndex]) <= 57
        ) {
            m = m * 10 + uint(uint8(_instructions[currentIndex]) - 48);
            currentIndex++;
        }
        parsed.mCol = m;
        // Skip a whitespace, "title" and a whitespace
        currentIndex += 7;

        // Determine maxLength as smaller of 60 chars or remaining _instructions
        uint maxLength = currentIndex + 60 < _instructions.length
            ? currentIndex + 60
            : _instructions.length;

        // Initialize title array with size up to maxLength
        bytes memory title = new bytes(maxLength - currentIndex);

        // Append characters to title within maxLength limit
        uint titleIndex = 0;
        while (currentIndex < maxLength) {
            title[titleIndex++] = _instructions[currentIndex++];
        }

        // Set the title in the parsed struct
        parsed.title = string(title);

        return parsed;
    }

    function getShapeInstr(
        bytes memory _instructions
    ) internal pure returns (ART0x1Types.ShapeInstructions memory shapeInstr) {
        // Get base shape attrs and store on shapeInstr
        uint currentIndex = getBaseShape(_instructions, shapeInstr);

        // Count number of repeat rows and cols
        (uint repeatRowCount, uint repeatColCount) = getRepeatCounts(
            _instructions,
            currentIndex
        );

        // Get repeat coords and store on shapeInstr
        getRepeatCoords(
            _instructions,
            currentIndex,
            repeatRowCount,
            repeatColCount,
            shapeInstr
        );

        return shapeInstr;
    }

    function getBaseShape(
        bytes memory _instructions,
        ART0x1Types.ShapeInstructions memory shapeInstr
    ) internal pure returns (uint currentIndex) {
        // skip shade id, a whitespace, "sym" and a whitespace
        currentIndex = 6;

        // Get sym
        shapeInstr.sym = _instructions[currentIndex];

        // Skip a whitespace, "arr" and  whitespace
        currentIndex += 6;

        // Get arr
        shapeInstr.arr = uint8(_instructions[currentIndex++]) - 48;

        // Parsing loop for row, col, nR, and nC values
        for (uint8 i = 0; i < 4; ) {
            // Skip index based on key lengths
            currentIndex += (i == 0 || i == 1) ? 5 : 4;

            // Parse the value using parseInt16 function
            (int16 parsedValue, uint nextIndex) = parseInt16(
                _instructions,
                currentIndex
            );
            currentIndex = nextIndex;

            // Assign the parsed value to the corresponding field
            if (i == 0) {
                shapeInstr.row = parsedValue;
            } else if (i == 1) {
                shapeInstr.col = parsedValue;
            } else if (i == 2) {
                shapeInstr.nR = parsedValue;
            } else {
                shapeInstr.nC = parsedValue;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getRepeatCounts(
        bytes memory _instructions,
        uint currentIndex
    ) internal pure returns (uint repeatRowCount, uint repeatColCount) {
        // Loop through _instructions and count number of repeat rows and cols
        for (uint i = currentIndex; i < _instructions.length; ) {
            if (_instructions[i] == "r") {
                repeatRowCount++;
            } else if (_instructions[i] == "c") {
                repeatColCount++;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getRepeatCoords(
        bytes memory _instructions,
        uint currentIndex,
        uint repeatRowCount,
        uint repeatColCount,
        ART0x1Types.ShapeInstructions memory shapeInstr
    ) internal pure {
        shapeInstr.repeatRows = new int16[](repeatRowCount);
        shapeInstr.repeatCols = new int16[](repeatColCount);

        repeatRowCount = 0;
        repeatColCount = 0;

        uint startIndex;

        while (currentIndex < _instructions.length) {
            if (repeatRowCount >= 9 && repeatColCount >= 9) {
                currentIndex += 5; // two-digit repeatKeys
                startIndex = currentIndex - 4; // whitespace, XX and "r" or "c"
            } else {
                currentIndex += 4; // single-digit repeatKeys
                startIndex = currentIndex - 3; // whitespace, X and "r" or "c"
            }

            if (currentIndex < _instructions.length) {
                (int16 parsedValue, uint nextIndex) = parseInt16(
                    _instructions,
                    currentIndex
                );

                currentIndex = nextIndex;

                if (uint8(_instructions[startIndex]) == 114) {
                    shapeInstr.repeatRows[repeatRowCount] = parsedValue;
                    repeatRowCount += 1;
                } else {
                    shapeInstr.repeatCols[repeatColCount] = parsedValue;
                    repeatColCount += 1;
                }
            }
        }
    }

    function parseInt16(
        bytes memory _instructions,
        uint start
    ) internal pure returns (int16, uint) {
        int16 n = 0;
        bool isNegative = false;

        if (_instructions[start] == bytes1("-")) {
            isNegative = true;
            start++;
        }

        while (
            start < _instructions.length &&
            uint8(_instructions[start]) >= 48 &&
            uint8(_instructions[start]) <= 57
        ) {
            uint8 currentChar = uint8(_instructions[start]);

            n = n * 10 + int16(int256(uint(currentChar) - 48));
            start++;
        }

        if (isNegative) {
            n = -n;
        }

        return (n, start);
    }

    // ------------------------------------------------------------------------
    // UTILS
    // ------------------------------------------------------------------------

    function uintToString(uint _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint temp = _value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function abs(int16 a) internal pure returns (int16) {
        return a >= 0 ? a : -a;
    }

    function addressToString(
        address _addr
    ) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes20 value = bytes20(_addr);
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";

        for (uint i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }

        return string(str);
    }
}
