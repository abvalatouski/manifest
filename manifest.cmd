@ echo off

rem.Copyright © 2023 Aliaksei Valatouski ^<abvalatouski@gmail.com^>
rem.
rem.Permission is hereby granted, free of charge, to any person obtaining a copy
rem.of this software and associated documentation files (the “Software”),
rem.to deal in the Software without restriction, including without limitation
rem.the rights to use, copy, modify, merge, publish, distribute, sublicense,
rem.and/or sell copies of the Software, and to permit persons to whom
rem.the Software is furnished to do so, subject to the following conditions:
rem.
rem.The above copyright notice and this permission notice shall be included
rem.in all copies or substantial portions of the Software.
rem.
rem.THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
rem.OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
rem.FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
rem.THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
rem.LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
rem.FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
rem.IN THE SOFTWARE.

:main (
    setlocal enabledelayedexpansion
    goto :parse-options
:options-were-parsed
    call :generate-manifest
    exit /b !errorlevel!
)

:usage (
    echo.Generates a manifest file for a Salesforce package.
    echo.
    echo.    %~n1 package [/?] [/v api-version]
    echo.
    echo.Options
    echo.
    echo.    package         Path to package folder.
    echo.
    echo.    /?              Show this help message.
    echo.                    Other options will be ignored.
    echo.
    echo.    /v api-version  Used API version.
    echo.                    Unless is set the latest API version among all package
    echo.                    members will be used.
    echo.
    echo.    Options can be placed in any order.
    echo.    In case of duplication newer options will override older ones.
    echo.    Unknown option will be treated as a package path.
    echo.
    echo.Examples
    echo.
    echo.    ^> %~n1 SFDX-PROJECT\force-app\main\default /v 42.69
    echo.    ^<?xml version="1.0" encoding="UTF-8"?^>
    echo.    ^<Package^ xmlns="http://soap.sforce.com/2006/04/metadata"^>
    echo.        ...
    echo.        ^<version^>42.69^</version^>
    echo.    ^</Package^>
    echo.
    echo.Notes
    echo.
    echo.    The script assumes that the given package has correct folder structure.
    echo.    Also it assumes that the package has at least one member in it.
    echo.
    echo.Source Code
    echo.
    echo.    Written by Aliaksei Valatouski ^<abvalatouski@gmail.com^>.
    echo.    The source code is licensed under the MIT License.
    echo.
    echo.    See 'type %~f1'
    echo.    or 'https://github.com/abvalatouski/manifest'.

    exit /b
)

:parse-options (
    set command=%~f0
    shift

    set package=
    set api-version=

:parse-option:
    if "%0" == "/?" (
        call :usage %command%
        endlocal
        exit /b
    )  else if /i "%0" == "/v" (
        if "%1" == "" (
            call :option-error^
                %command%^
                "Expected an API version after %0."
            endlocal
            exit /b 1
        )

        set api-version=%1
        shift
        shift
        goto :parse-option
    ) else if not "%0" == "" (
        if not exist "%0" (
            call :option-error^
                %command%^
                "Package folder '%0' does not exist."
            endlocal
            exit /b 1
        )

        set package=%0
        shift
        goto :parse-option
    )

    if "%package%" == "" (
        call :option-error^
            %command%^
            "Package path not set."
        endlocal
        exit /b 1
    )

    goto :options-were-parsed
)

:option-error (
    >&2 echo.%~2
    >&2 echo.See '%~n1 /? ^| more'.
    exit /b
)

:generate-manifest (
    echo.^<?xml version="1.0" encoding="UTF-8"?^>
    echo.^<Package^ xmlns="http://soap.sforce.com/2006/04/metadata"^>

    set last-type=
    set latest-api-version=
    for /f "tokens=*" %%a in ('dir /b "%package%"') do (
        if "%%~xa" == "" (
            for /f "tokens=*" %%b in ('dir /b "%package%\%%a"') do (
                set filepath=%package%\%%a\%%b
                set extension=%%~xb

                call :get-metadata-path "metadata"

                if not "!metadata!" == "" (
                    call :get-metadata-type "type" "!metadata!"

                    for /f "tokens=3 delims=<>" %%c in ('type !metadata! ^| findstr apiVersion') do (
                        if "!latest-api-version!" == "" (
                            set latest-api-version=%%c
                        ) else if %%c gtr !latest-api-version! (
                            set latest-api-version=%%c
                        )
                    )

                    if /i not "!last-type!" == "!type!" (
                        if not "!last-type!" == "" (
                            echo.    ^</types^>
                        )

                        set last-type=!type!
                        echo.    ^<types^>
                        echo.        ^<name^>!type!^</name^>
                    )

                    for /f "tokens=1 delims=." %%c in ("%%b") do (
                        set name=%%c
                    )

                    echo.        ^<members^>!name!^</members^>
                )
            )
        )
    )

    if not "!last-type!" == "" (
        echo.    ^</types^>
    )

    if "!api-version!" == "" (
        set api-version=!latest-api-version!
    )

    echo.    ^<version^>!api-version!^</version^>

    echo.^</Package^>

    exit /b
)

:get-metadata-path (
    set "%~1="
    if /i "!extension!" == ".xml" (
        set "%~1=!filepath!"
    ) else if "!extension!" == "" (
        for /f "tokens=*" %%c in ('dir /b "!filepath!"') do (
            if /i "%%~xc" == ".xml" (
                set "%~1=!filepath!\%%c"
            )
        )
    )

    exit /b
)

:get-metadata-type (
    set "%~1="
    for /f "skip=1" %%c in (!%~2!) do (
        if "!%~1!" == "" (
            set "%~1=%%c"
        )
    )

    set "%~1=!%~1:~1!"
    exit /b
)
