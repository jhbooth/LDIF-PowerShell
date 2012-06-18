namespace BoothBilt.Utility.LdifTool
{

    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.IO;
    using System.Management.Automation;
    using System.Text;
    using System.Text.RegularExpressions;

    [System.Runtime.InteropServices.ComVisible(false)]
    [Cmdlet(VerbsData.Export, "Ldif")]
    sealed public class ExportLdifCommand : Cmdlet, IDisposable
    {
        // $excludedProperties = 'dn','changetype','objectClass','SideIndicator'

        #region Class Members
        StreamWriter ldifStreamWriter;
        Regex binaryAttribute = new Regex(@"^(?<attrName>[\w-;]+)_binary$", RegexOptions.IgnoreCase);
        #endregion

        #region Parameters
        /// <summary>
        /// LiteralPath parameter is for specifying path to LDIF file
        /// </summary>
        [Alias("Path")]
        [Parameter(Position = 0, Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string LiteralPath { get; set; }

        [Parameter(Position = 1, Mandatory = true, ValueFromPipeline = true)]
        public Collection<PSObject> ldifObjects;
        #endregion

        #region Protected Override Methods

        protected override void BeginProcessing()
        {
            string path;

            if (Path.IsPathRooted(this.LiteralPath))
            {
                path = Path.GetFullPath(this.LiteralPath);
            }
            else
            {
                //SessionState ss = new SessionState();
                path = Path.GetFullPath(Path.Combine((new SessionState()).Path.CurrentFileSystemLocation.Path, this.LiteralPath));
            }

            try
            {
                ldifStreamWriter = new StreamWriter(path);
            }
            catch (Exception ex)
            {
                ThrowTerminatingError(new ErrorRecord(ex, "1", ErrorCategory.OpenError, ldifStreamWriter));
            }
        }

        protected override void ProcessRecord()
        {
            PSMemberInfoCollection<PSPropertyInfo> properties;
            ReadOnlyPSMemberInfoCollection<PSPropertyInfo> propertyValues;
            PSPropertyInfo ps;
            foreach (PSObject entry in this.ldifObjects)
            {
                properties = entry.Properties;

                // Find the DN and output it first
                propertyValues = properties.Match("dn", PSMemberTypes.NoteProperty);
                if (propertyValues.Count > 0)
                {
                    properties.Remove("dn");
                    ps = propertyValues[0];
                    ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", ps.Name, ps.Value));
                }

                propertyValues = properties.Match("changetype", PSMemberTypes.NoteProperty);
                if (propertyValues.Count > 0)
                {
                    properties.Remove("changetype");
                    ps = propertyValues[0];
                    ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", ps.Name, ps.Value));
                }

                propertyValues = properties.Match("objectclass");
                if (propertyValues.Count > 0)
                {
                    properties.Remove("objectclass");
                    ps = propertyValues[0];
                    if (ps.TypeNameOfValue == "System.Collections.ArrayList")
                    {
                        foreach (string s in (System.Collections.ArrayList)ps.Value)
                        {
                            ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", ps.Name, s));
                        }
                    }
                }

                propertyValues = properties.Match("sideIndicator");
                if (propertyValues.Count > 0)
                {
                    properties.Remove("sideIndicator");

                }

                foreach (PSPropertyInfo p in properties)
                {
                    switch (p.TypeNameOfValue)
                    {
                        case "System.String":
                            if (binaryAttribute.IsMatch(p.Name))
                            {
                                string aName = binaryAttribute.Match(p.Name).Groups["attrName"].Value;
                                ldifStreamWriter.WriteLine(string.Format(@"{0}:: {1}", aName, p.Value));
                            }
                            else
                            {
                                ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", p.Name, p.Value));
                            }

                            break;

                        case "System.Collections.ArrayList":

                            if (binaryAttribute.IsMatch(p.Name))
                            {
                                string aName = binaryAttribute.Match(p.Name).Groups["attrName"].Value;
                                foreach (string s in (System.Collections.ArrayList)p.Value)
                                {
                                    ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", aName, s));
                                }
                            }
                            else
                            {
                                foreach (string s in (System.Collections.ArrayList)p.Value)
                                {
                                    ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", p.Name, s));
                                }
                            }

                            break;

                        default:
                            break;
                    }
                }

                ldifStreamWriter.WriteLine();
            }
        }

        protected override void EndProcessing()
        {
            if (ldifStreamWriter != null)
            {
                ldifStreamWriter.Dispose();
            }
        }

        protected override void StopProcessing()
        {
            if (ldifStreamWriter != null)
            {
                ldifStreamWriter.Dispose();
            }
        }

        /*
process{

    try
    {
        if ($LDIF -is [array])
        {
            $LDIF | Foreach-Object { Write-LdifEntry $stream $_ }
        }


        if ($LDIF -is [System.Management.Automation.PSCustomObject])
        {
            Write-LdifEntry $stream $LDIF
        }
    }
    catch
    {
        if ($stream)
        {
            $stream.Dispose()
            $stream = $null
        }

    }
    finally
    {
    }
    */

        #endregion

        #region IDisposable implementation
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (ldifStreamWriter != null)
                {
                    ldifStreamWriter.Dispose();
                    ldifStreamWriter = null;
                }
            }
        }
        #endregion
    }
}
/*
function Write-LdifEntry
{
    param($Path,$ldifEntry)

        $dn = 'dn: {0}' -f $ldifEntry.dn
        $Path.WriteLine($dn)

        if (Get-Member -InputObject $ldifEntry -Name changetype)
        {
            $ct = 'changetype: {0}' -f $ldifEntry.changetype
            $Path.WriteLine($ct)
        }

        if (Get-Member -InputObject $ldifEntry -Name objectClass)
        {
            $values = @($ldifEntry.objectClass)
            $values | Foreach-Object {

            $oc = 'objectClass: {0}' -f $_
            $Path.WriteLine($oc)
            }
        }

        $attributes = Get-Member -InputObject $ldif -MemberType NoteProperty | Where-Object {$excludedProperties -notcontains $_.Name }


        foreach ($attr in $attributes)
        {
            $values = @($ldifEntry.$($attr.Name))
            if ($values)
            {
                $values | Sort-Object | Foreach-Object {
                    if ($attr.Name -match '^(?<attrName>[\w-;]+)_binary$') {
                        $aName = $matches['attrName']
                        $line = '{0}:: {1}' -f $aName, $_
                    } else {
                        $line = '{0}: {1}' -f $attr.Name, $_
                    }
                    $Path.WriteLine($line)
                }
            }
        }

        $Path.WriteLine('')

}
*/
