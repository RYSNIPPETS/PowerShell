@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Standalone snippets run unattended. Legacy confirmation arguments are accepted without prompting.
        'PSUseShouldProcessForStateChangingFunctions'
        'PSUseSupportsShouldProcess'

        # Some snippets provide host status or optional selection interfaces.
        'PSAvoidUsingWriteHost'

        # PowerShell 7 defaults to UTF-8 without a BOM; requiring a BOM is a Windows PowerShell convention.
        'PSUseBOMForUnicodeEncodedFile'
    )
}
