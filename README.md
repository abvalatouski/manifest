# `sflist`

Download the script with:

```console
powershell -c "Invoke-WebRequest -Outfile sflist.cmd -Uri https://raw.githubusercontent.com/abvalatouski/sflist/master/sflist.cmd"
```

Shortened help nessage:

```console
Generates a manifest file for a Salesforce package.

    sflist package [/?] [/i] [/v api-version]

Options

    package         Path to package folder.

    /?              Show this help message.
                    Other options will be ignored.
    
    /i              Outputs manifest directly in the package folder
                    as `package.xml`.
                    ==================
                    Mnemonic: in-place

    /v api-version  Used API version.
                    Unless is set the latest API version among all package
                    members will be used.

    Options can be placed in any order.
    In case of duplication newer options will override older ones.
    Unknown option will be treated as a package path.

Examples

    > sflist SOME-SFDX-PROJECT\force-app\main\default /v 42.69
    <?xml version="1.0" encoding="UTF-8"?>
    <Package xmlns="http://soap.sforce.com/2006/04/metadata">
        ...
        <version>42.69</version>
    </Package>
```
