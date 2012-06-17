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
        #region Class Members
        StreamWriter ldifStreamWriter;
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
        public Collection<PSObject> ldifEntry;
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
            ldifStreamWriter.WriteLine(ldifEntry.Count);
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
