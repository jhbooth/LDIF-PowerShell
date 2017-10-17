namespace BoothBilt.Utility.LdifTool
{
    using System;
    using System.Collections;
    using System.IO;
    using System.Management.Automation;
    using System.Text;
    using System.Text.RegularExpressions;

    [System.Runtime.InteropServices.ComVisible(false)]
    [Cmdlet(VerbsData.Import, "Ldif")]
    sealed public class ImportLdifCommand : Cmdlet, IDisposable
    {
        #region Class Members

        private StreamReader ldifStreamReader;

        private Regex attributeMatch = new Regex(@"\A(?i)(?<attrName>[a-z][-a-z0-9;]*?):\s(?<attrValue>.+)\Z", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private Regex binaryAttributeMatch = new Regex(@"\A(?i)(?<attrName>[a-z][-a-z0-9;]*?)(;binary)?::\s(?<attrValue>.+)\Z", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private ScriptBlock reverseDNScriptBlock = ScriptBlock.Create(@"$x = $this.dn -split '(?<!\\),';[array]::Reverse($x);$x -join ','");

        #endregion Class Members

        #region Parameters

        /// <summary>
        /// LiteralPath parameter is for specifying path to LDIF file
        /// </summary>
        [Alias("Path")]
        [Parameter(Position = 0, Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string LiteralPath { get; set; }

        #endregion Parameters

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
                path = Path.GetFullPath(Path.Combine((new SessionState()).Path.CurrentFileSystemLocation.Path, this.LiteralPath));
            }

            try
            {
                // Open with default encoding to read high order ASCII characters (accented characters primarily)
                ldifStreamReader = new StreamReader(path, Encoding.Default);
            }
            catch (Exception ex)
            {
                ThrowTerminatingError(new ErrorRecord(ex, "1", ErrorCategory.OpenError, ldifStreamReader));
            }
        }

        protected override void ProcessRecord()
        {
            PSObject ldifEntry = null;
            string attrName = null;
            string attrValue = null;

            while (!ldifStreamReader.EndOfStream)
            {
                string line = ldifStreamReader.ReadLine();

                while (ldifStreamReader.Peek() == 32)
                {
                    string continuation = ldifStreamReader.ReadLine();
                    line += continuation.Substring(1);
                }

                //  If the version marker is there, ignore it
                if (Regex.IsMatch(line, @"^version.+$", RegexOptions.IgnoreCase))
                {
                    continue;
                }

                // Ignore comment lines
                if (Regex.IsMatch(line, @"^#.*$", RegexOptions.IgnoreCase))
                {
                    continue;
                }

                // If it is DN, then we are starting a new object
                if (Regex.IsMatch(line, @"^dn: .+$", RegexOptions.IgnoreCase))
                {
                    ldifEntry = new PSObject();
                    //  Give object a type name which can be identified later
                    ldifEntry.TypeNames.Insert(0, "BoothBilt.Utility.LdifTool.LdifEntry");
                }

                // If it is an empty line, then we are finished for this object
                // Ship it!
                if (Regex.IsMatch(line, @"^$", RegexOptions.IgnoreCase))
                {
                    WriteObject(ldifEntry);

                    // get rid of extra blank lines
                    while (ldifStreamReader.Peek() == 0x0D)
                    {
                        ldifStreamReader.ReadLine();
                    }

                    continue;
                }

                if (this.attributeMatch.IsMatch(line))
                {
                    attrName = this.attributeMatch.Match(line).Groups["attrName"].ToString();
                    attrValue = this.attributeMatch.Match(line).Groups["attrValue"].ToString();
                }
                else if (this.binaryAttributeMatch.IsMatch(line))
                {
                    attrName = this.binaryAttributeMatch.Match(line).Groups["attrName"].ToString() + "_binary";
                    attrValue = this.binaryAttributeMatch.Match(line).Groups["attrValue"].ToString();
                }
                else
                {
                    WriteError(new ErrorRecord(new InvalidDataException(string.Format("Invalid line: {0}", line)), "errid", ErrorCategory.InvalidData, ldifEntry));
                    continue;
                }

                // check if this is a changetype attribute, and if it is, make sure that it is an add
                // otherwise, throw an error for this entry and read to the end of the entry
                if (attrName.ToLowerInvariant() == "changetype")
                {
                    string av = attrValue.ToLowerInvariant();
                    if (av != "add" && av != "ntdsschemaadd")
                    {
                        do
                        {
                            line = ldifStreamReader.ReadLine();
                            if (line == null) { break; }
                        } while (!Regex.IsMatch(line, @"^$"));

                        WriteError(new ErrorRecord(new InvalidDataException(string.Format("Invalid changetype: {0}", attrValue)), "errid", ErrorCategory.InvalidArgument, ldifEntry));

                        continue;
                    }
                }

                if (ldifEntry.Properties.Match(attrName).Count > 0)
                {
                    string test = ldifEntry.Properties[attrName].TypeNameOfValue;
                    if (test == "System.String")
                    {
                        ArrayList list = new ArrayList();
                        list.Add(ldifEntry.Properties[attrName].Value);
                        list.Add(attrValue);
                        ldifEntry.Properties[attrName].Value = list;
                    }
                    else if (test == "System.Collections.ArrayList")
                    {
                        PSPropertyInfo info = ldifEntry.Properties[attrName];
                        if (info.IsSettable)
                        {
                            ArrayList lst = (ArrayList)info.Value;
                            lst.Add(attrValue);
                        }
                    }
                }
                else
                {
                    ldifEntry.Properties.Add(new PSNoteProperty(attrName, attrValue.ToString()));
                }
            }
        }

        protected override void EndProcessing()
        {
            if (ldifStreamReader != null)
            {
                ldifStreamReader.Dispose();
            }
        }

        protected override void StopProcessing()
        {
            if (ldifStreamReader != null)
            {
                ldifStreamReader.Dispose();
            }
        }

        #endregion Protected Override Methods

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
                if (ldifStreamReader != null)
                {
                    ldifStreamReader.Dispose();
                    ldifStreamReader = null;
                }
            }
        }

        #endregion IDisposable implementation
    }
}