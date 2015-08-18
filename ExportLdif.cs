namespace BoothBilt.Utility.LdifTool
{
    using System;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.IO;
    using System.Management.Automation;
    using System.Text.RegularExpressions;

    [System.Runtime.InteropServices.ComVisible(false)]
    [Cmdlet(VerbsData.Export, "Ldif")]
    sealed public class ExportLdifCommand : Cmdlet, IDisposable
    {
        #region Class Members
        StreamWriter ldifStreamWriter;
        Regex binaryAttribute = new Regex(@"^(?<attrName>[\w-;]+)_binary$", RegexOptions.IgnoreCase);
        List<string> excludedProperties = new List<string>();
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
            this.excludedProperties.Add("dn");
            this.excludedProperties.Add("changetype");
            this.excludedProperties.Add("objectclass");
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
                    ps = propertyValues[0];
                    ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", ps.Name, ps.Value));
                }

                propertyValues = properties.Match("changetype", PSMemberTypes.NoteProperty);
                if (propertyValues.Count > 0)
                {
                    ps = propertyValues[0];
                    ldifStreamWriter.WriteLine(string.Format(@"{0}: {1}", ps.Name, ps.Value));
                }

                propertyValues = properties.Match("objectclass");
                if (propertyValues.Count > 0)
                {
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
                    if (this.excludedProperties.Contains(p.Name.ToLowerInvariant()))
                    {
                        continue;
                    }
                    
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
                                    ldifStreamWriter.WriteLine(string.Format(@"{0}:: {1}", aName, s));
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

                        case "System.String[]":

                            if (binaryAttribute.IsMatch(p.Name))
                            {
                                string aName = binaryAttribute.Match(p.Name).Groups["attrName"].Value;
                                foreach (string s in (String[])p.Value)
                                {
                                    ldifStreamWriter.WriteLine(string.Format(@"{0}:: {1}", aName, s));
                                }
                            }
                            else
                            {
                                foreach (string s in (String[])p.Value)
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
