namespace BoothBilt.Utility.LdifTool
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.IO;
    using System.Management.Automation;
    using System.Text;
    using System.Text.RegularExpressions;

    [System.Runtime.InteropServices.ComVisible(false)]
    [Cmdlet(VerbsData.Import, "Ldif")]
    sealed public class ImportLdifCommand : PSCmdlet, IDisposable
    {
        #region Class Members

        private StreamReader ldifStreamReader;

        private readonly Regex dnCheck = new Regex(@"\Adn::?\s(?<dnValue>.+)\Z", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private readonly Regex attributeMatch = new Regex(@"\A(?i)(?<attrName>[a-z][-a-z0-9;]*?):\s(?<attrValue>.+)\Z", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private readonly Regex binaryAttributeMatch = new Regex(@"\A(?i)(?<attrName>[a-z][-a-z0-9;]*?)(;binary)?::\s(?<attrValue>.+)\Z", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private ScriptBlock reverseDNScriptBlock = ScriptBlock.Create(@"$x = $this.dn -split '(?<!\\),';[array]::Reverse($x);$x -join ','");

        //private bool wasSpecified = MyInvocation.BoundParameters.ContainsKey("SchemaMap");

        private bool haveMap;

        #endregion Class Members

        #region Parameters

        /// <summary>
        /// LiteralPath parameter is for specifying path to LDIF file
        /// </summary>
        [Alias("Path")]
        [Parameter(Position = 0, Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string LiteralPath { get; set; }

        [Parameter]
        public SwitchParameter Unicode { get; set; }

        [Alias("Map")]
        [Parameter(Mandatory = false)]
        public Hashtable SchemaMap { get; set; }

        #endregion Parameters

        #region Protected Override Methods

        protected override void BeginProcessing()
        {
            string path;

            haveMap = MyInvocation.BoundParameters.ContainsKey("SchemaMap");

            if (haveMap)
            {
                WriteDebug("I have a map!!!");
            }

            if (Path.IsPathRooted(this.LiteralPath))
            {
                path = Path.GetFullPath(this.LiteralPath);
            }
            else
            {
                path = Path.GetFullPath(Path.Combine((new SessionState()).Path.CurrentFileSystemLocation.Path, this.LiteralPath));
            }
            WriteDebug(string.Format(@"Input path is {0}", path));

            try
            {
                if (Unicode)
                {
                    // Unicode specified, so read as such
                    ldifStreamReader = new StreamReader(path, Encoding.Unicode);
                }
                else
                {
                    // Open with default encoding to read high order ASCII characters (accented characters primarily)
                    ldifStreamReader = new StreamReader(path, new UTF8Encoding());
                }
                // Check the beginning of the file to see if it begins with white space, if so
                // read until the first non-whitespace character
                List<char> whitespace = new List<char>() { (char)13, (char)10, (char)9, (char)32 };

                while (whitespace.Contains((char)ldifStreamReader.Peek()))
                {
                    ldifStreamReader.Read();
                }
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
                if (dnCheck.IsMatch(line))
                {
                    ldifEntry = new PSObject();
                    //  Give object a type name which can be identified later
                    ldifEntry.TypeNames.Insert(0, "BoothBilt.LdifTools.LdifEntry");

                    string dnValue = dnCheck.Match(line).Groups["dnValue"].ToString();
                    if (IsBase64String(dnValue))
                    {
                        dnValue = Base64Decode(dnValue);
                        // Identify the entry as having a Base64 DN
                        // This can then be used -- by Select-Object, for example -- to control processing further down the pipeline
                        if (ldifEntry.TypeNames.Contains("LdifEntry.Base64"))
                        {
                            // we are good; 
                        }
                        else
                        {
                            ldifEntry.TypeNames.Add("LdifEntry.Base64");
                        }
                    }

                    WriteDebug(dnValue);
                    ldifEntry.Properties.Add(new PSNoteProperty("dn", dnValue));
                    continue;
                }

                // If it is an empty line, or a line with only whitespace then we are finished for this object
                // Ship it!
                if (Regex.IsMatch(line, @"^\s*$", RegexOptions.IgnoreCase))
                {
                    if (null != ldifEntry)
                    {
                        WriteObject(ldifEntry);
                        ldifEntry = null;
                    }

                    // get rid of extra blank lines
                    while (ldifStreamReader.Peek() == 0x0D)
                    {
                        ldifStreamReader.ReadLine();
                    }

                    continue;
                }

                if (attributeMatch.IsMatch(line))
                {
                    attrName = attributeMatch.Match(line).Groups["attrName"].ToString();
                    attrValue = attributeMatch.Match(line).Groups["attrValue"].ToString();
                }
                else if (binaryAttributeMatch.IsMatch(line))
                {
                    attrName = binaryAttributeMatch.Match(line).Groups["attrName"].ToString();
                    attrValue = binaryAttributeMatch.Match(line).Groups["attrValue"].ToString();

                    if (haveMap)
                    {
                        if (SchemaMap.ContainsKey(attrName))
                        {
                            if (CanConvert(attrName))
                            {
                                if (IsBase64String(attrValue))
                                {
                                    attrValue = Base64Decode(attrValue);

                                    // Identify the entry as having at least one Base64 attribute that has been converted to UTF8
                                    // This can then be used -- by Select-Object, for example -- to control processing further down the pipeline
                                    if (ldifEntry.TypeNames.Contains("LdifEntry.Base64"))
                                    {
                                        // we are good; 
                                    }
                                    else
                                    {
                                        ldifEntry.TypeNames.Add("LdifEntry.Base64");
                                    }

                                }
                            }
                        }
                    }
                    else
                    {
                        attrName += "_binary";
                    }
                }
                else
                {
                    WriteError(new ErrorRecord(new InvalidDataException(string.Format("Invalid line: {0}", line)), "errid", ErrorCategory.InvalidData, ldifEntry));
                    continue;
                }

                // check if this is a changetype attribute, and if it is, make sure that it is an add
                // otherwise, throw an error for this entry, read to the end of the entry, and null out ldifentry
                if (attrName.ToLowerInvariant() == "changetype")
                {
                    string av = attrValue.ToLowerInvariant();
                    if (av != "add" && av != "ntdsschemaadd")
                    {
                        WriteError(new ErrorRecord(new InvalidDataException(string.Format("Invalid changetype: {0}", attrValue)), "errid", ErrorCategory.InvalidArgument, ldifEntry));
                        ldifEntry = null;

                        do
                        {
                            line = ldifStreamReader.ReadLine();
                            if (line == null) { break; }
                        } while (!Regex.IsMatch(line, @"^\s*$"));


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

        #region Base64 functions
        private bool CanConvert(string attrName)
        {
            bool bReturn = false;

            switch (SchemaMap[attrName])
            {
                case "2.5.5.3":
                case "2.5.5.4":
                case "2.5.5.12":
                    bReturn = true;
                    break;
                default:
                    break;
            }

            return bReturn;
        }

        private string Base64Decode(string base64EncodedData)
        {
            var base64EncodedBytes = System.Convert.FromBase64String(base64EncodedData);
            return System.Text.Encoding.UTF8.GetString(base64EncodedBytes);
        }

        private bool IsBase64String(string testString)
        {
            testString = testString.Trim();
            return (testString.Length % 4 == 0) && Regex.IsMatch(testString, @"^[a-zA-Z0-9\+/]*={0,3}$", RegexOptions.None);
        }

        #endregion Base64 functions

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