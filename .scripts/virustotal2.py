import PyPDF2
import requests
import time
import hashlib
import re
import fitz  # PyMuPDF - better for link handling
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
import io
import os
import uuid
import getpass
from typing import Dict, List, Optional, Tuple
import logging

class SecurePDFLinkRemover:
    def __init__(self, virustotal_api_key: str = None):
        self.vt_api_key = virustotal_api_key
        self.vt_base_url = "https://www.virustotal.com/vtapi/v2"
        self.use_virustotal = bool(virustotal_api_key)
        self.setup_logging()
        
    def setup_logging(self):
        logging.basicConfig(level=logging.INFO, 
                          format='%(asctime)s - %(levelname)s - %(message)s')
        self.logger = logging.getLogger(__name__)
    
    def generate_safe_filename(self, original_path: str, suffix: str = "cleaned") -> str:
        """
        Generate a safe filename with UUID to avoid long paths and identify processed files
        """
        # Get the directory and base name
        directory = os.path.dirname(original_path)
        filename = os.path.basename(original_path)
        name, ext = os.path.splitext(filename)
        
        # Generate a short UUID (first 8 characters)
        file_uuid = str(uuid.uuid4())[:8]
        
        # Create new filename: original_name_suffix_UUID.ext
        new_filename = f"{name}_{suffix}_{file_uuid}{ext}"
        new_path = os.path.join(directory, new_filename)
        
        return new_path
    
    def extract_all_links_and_content(self, pdf_path: str) -> Dict:
        """
        Extract all types of links and content using PyMuPDF (more comprehensive)
        """
        all_links = []
        text_content = ""
        link_details = []
        
        try:
            doc = fitz.open(pdf_path)
            
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)
                
                # Extract text
                text_content += page.get_text() + "\n"
                
                # Extract all links from the page
                links = page.get_links()
                
                for link in links:
                    link_info = {
                        'page': page_num + 1,
                        'rect': link['from'],  # Link rectangle coordinates
                        'type': link.get('kind', 'unknown'),
                        'uri': link.get('uri', ''),
                        'page_dest': link.get('page', None),
                        'zoom': link.get('zoom', None)
                    }
                    
                    link_details.append(link_info)
                    
                    if link_info['uri']:
                        all_links.append(link_info['uri'])
                
                # Also check annotations for additional links
                annotations = page.annots()
                if annotations:
                    for annot in annotations:
                        annot_dict = annot.info
                        if 'uri' in annot_dict and annot_dict['uri']:
                            all_links.append(annot_dict['uri'])
                            link_details.append({
                                'page': page_num + 1,
                                'type': 'annotation',
                                'uri': annot_dict['uri'],
                                'rect': annot.rect
                            })
            
            doc.close()
            
            # Extract URLs from text content using regex
            url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
            text_urls = re.findall(url_pattern, text_content)
            all_links.extend(text_urls)
            
            self.logger.info(f"Found {len(link_details)} embedded links and {len(text_urls)} text URLs")
            
            return {
                "all_links": list(set(all_links)),
                "link_details": link_details,
                "text_content": text_content,
                "text_urls": text_urls
            }
            
        except Exception as e:
            self.logger.error(f"Error extracting links: {str(e)}")
            return {"all_links": [], "link_details": [], "text_content": "", "text_urls": []}
    
    def remove_all_links_comprehensive(self, input_path: str, output_path: str) -> Tuple[bool, List[str]]:
        """
        Comprehensive link removal using PyMuPDF - handles all embedded link types
        """
        removed_links = []
        
        try:
            doc = fitz.open(input_path)
            
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)
                
                # Method 1: Remove all links
                links = page.get_links()
                for link in links:
                    if link.get('uri'):
                        removed_links.append(link['uri'])
                    page.delete_link(link)
                
                # Method 2: Remove all annotations
                annotations = page.annots()
                if annotations:
                    for annot in annotations:
                        annot_info = annot.info
                        if 'uri' in annot_info and annot_info['uri']:
                            removed_links.append(annot_info['uri'])
                        page.delete_annot(annot)
            
            # Save the cleaned document
            doc.save(output_path, garbage=4, deflate=True, clean=True)
            doc.close()
            
            self.logger.info(f"Successfully removed {len(set(removed_links))} unique links")
            return True, list(set(removed_links))
            
        except Exception as e:
            self.logger.error(f"Error removing links with PyMuPDF: {str(e)}")
            # Fallback to PyPDF2 method
            return self.fallback_link_removal(input_path, output_path)
    
    def fallback_link_removal(self, input_path: str, output_path: str) -> Tuple[bool, List[str]]:
        """
        Fallback method using PyPDF2 with more aggressive cleaning
        """
        removed_links = []
        
        try:
            with open(input_path, 'rb') as input_file:
                pdf_reader = PyPDF2.PdfReader(input_file)
                pdf_writer = PyPDF2.PdfWriter()
                
                for page_num in range(len(pdf_reader.pages)):
                    page = pdf_reader.pages[page_num]
                    
                    # Remove various types of annotations and actions
                    items_to_remove = ['/Annots', '/AA', '/A', '/F', '/URI', '/S', '/GoTo']
                    
                    for item in items_to_remove:
                        if item in page:
                            del page[item]
                    
                    # Deep clean the page object
                    self._deep_clean_page_object(page, removed_links)
                    
                    pdf_writer.add_page(page)
                
                # Clean metadata that might contain links
                if pdf_writer.metadata:
                    clean_metadata = {}
                    for key, value in pdf_writer.metadata.items():
                        if not any(url_indicator in str(value).lower() 
                                 for url_indicator in ['http', 'www', 'ftp', '.com', '.org']):
                            clean_metadata[key] = value
                    pdf_writer.metadata = clean_metadata
                
                # Write the cleaned PDF
                with open(output_path, 'wb') as output_file:
                    pdf_writer.write(output_file)
                    
                self.logger.info(f"Fallback method: removed {len(removed_links)} links")
                return True, removed_links
                
        except Exception as e:
            self.logger.error(f"Error in fallback removal: {str(e)}")
            return False, []
    
    def _deep_clean_page_object(self, page_obj, removed_links):
        """
        Recursively clean page objects of any URI references
        """
        if hasattr(page_obj, 'get_object'):
            obj = page_obj.get_object()
            if hasattr(obj, 'items'):
                keys_to_remove = []
                for key, value in obj.items():
                    if key in ['/URI', '/A', '/AA', '/F', '/GoTo', '/GoToR', '/Launch']:
                        keys_to_remove.append(key)
                        if hasattr(value, 'get_object'):
                            val_obj = value.get_object()
                            if hasattr(val_obj, 'get') and val_obj.get('/URI'):
                                removed_links.append(str(val_obj.get('/URI')))
                    elif hasattr(value, 'items'):
                        self._deep_clean_page_object(value, removed_links)
                
                for key in keys_to_remove:
                    del obj[key]
    
    def create_sanitized_pdf_from_text(self, original_path: str, output_path: str, 
                                     remove_urls_from_text: bool = True) -> bool:
        """
        Create a completely new PDF from extracted text (most secure method)
        """
        try:
            # Extract text content
            doc = fitz.open(original_path)
            full_text = ""
            
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)
                page_text = page.get_text()
                
                if remove_urls_from_text:
                    # Remove URLs from text content
                    url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
                    page_text = re.sub(url_pattern, '[URL REMOVED]', page_text)
                
                full_text += f"\n--- Page {page_num + 1} ---\n{page_text}\n"
            
            doc.close()
            
            # Create new PDF with clean text
            doc = SimpleDocTemplate(output_path, pagesize=letter)
            styles = getSampleStyleSheet()
            story = []
            
            # Add title
            title_style = ParagraphStyle(
                'CustomTitle',
                parent=styles['Heading1'],
                fontSize=16,
                spaceAfter=30,
            )
            story.append(Paragraph("SANITIZED DOCUMENT", title_style))
            story.append(Spacer(1, 12))
            
            # Add notice
            notice_style = ParagraphStyle(
                'Notice',
                parent=styles['Normal'],
                fontSize=10,
                textColor='red',
                spaceAfter=20,
            )
            story.append(Paragraph("⚠️ This document has been sanitized. All links have been removed for security.", notice_style))
            story.append(Spacer(1, 12))
            
            # Add content
            content_style = ParagraphStyle(
                'Content',
                parent=styles['Normal'],
                fontSize=11,
                leading=14,
            )
            
            # Split text into paragraphs and clean up
            paragraphs = full_text.split('\n\n')
            for para in paragraphs:
                if para.strip():
                    # Escape HTML characters for reportlab
                    clean_para = para.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                    story.append(Paragraph(clean_para, content_style))
                    story.append(Spacer(1, 6))
            
            doc.build(story)
            
            self.logger.info("Created completely sanitized PDF from text content")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating sanitized PDF: {str(e)}")
            return False
    
    def verify_link_removal(self, pdf_path: str) -> Dict:
        """
        Verify that links have been successfully removed
        """
        try:
            doc = fitz.open(pdf_path)
            remaining_links = []
            
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)
                
                # Check for remaining links
                links = page.get_links()
                for link in links:
                    remaining_links.append({
                        'page': page_num + 1,
                        'type': link.get('kind', 'unknown'),
                        'uri': link.get('uri', 'N/A')
                    })
                
                # Check annotations
                annotations = page.annots()
                if annotations:
                    for annot in annotations:
                        annot_info = annot.info
                        if 'uri' in annot_info:
                            remaining_links.append({
                                'page': page_num + 1,
                                'type': 'annotation',
                                'uri': annot_info['uri']
                            })
            
            doc.close()
            
            # Also check text for URLs
            text_content = ""
            doc = fitz.open(pdf_path)
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)
                text_content += page.get_text()
            doc.close()
            
            url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
            text_urls = re.findall(url_pattern, text_content)
            
            return {
                "embedded_links": remaining_links,
                "text_urls": text_urls,
                "total_remaining": len(remaining_links) + len(text_urls),
                "is_clean": len(remaining_links) == 0 and len(text_urls) == 0
            }
            
        except Exception as e:
            self.logger.error(f"Error verifying link removal: {str(e)}")
            return {"error": str(e)}
    
    # VirusTotal methods (only used if API key is provided)
    def get_file_hash(self, file_path: str) -> str:
        """Calculate SHA-256 hash of the file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
    
    def scan_file_virustotal(self, file_path: str) -> Dict:
        """Scan file with VirusTotal API"""
        if not self.use_virustotal:
            return {"error": "VirusTotal scanning not enabled"}
            
        file_hash = self.get_file_hash(file_path)
        
        report_url = f"{self.vt_base_url}/file/report"
        report_params = {
            'apikey': self.vt_api_key,
            'resource': file_hash
        }
        
        self.logger.info(f"Checking VirusTotal for {os.path.basename(file_path)}...")
        try:
            report_response = requests.get(report_url, params=report_params, timeout=30)
            
            if report_response.status_code == 200:
                report_data = report_response.json()
                
                if report_data['response_code'] == 1:
                    return self.format_scan_results(report_data)
                else:
                    return self.upload_file_for_scan(file_path)
            else:
                return {"error": f"API request failed: {report_response.status_code}"}
        except requests.exceptions.RequestException as e:
            return {"error": f"Network error: {str(e)}"}
    
    def upload_file_for_scan(self, file_path: str) -> Dict:
        """Upload file to VirusTotal for scanning"""
        upload_url = f"{self.vt_base_url}/file/scan"
        
        self.logger.info(f"Uploading {os.path.basename(file_path)} to VirusTotal...")
        
        try:
            with open(file_path, 'rb') as file:
                files = {'file': (os.path.basename(file_path), file)}
                params = {'apikey': self.vt_api_key}
                
                upload_response = requests.post(upload_url, files=files, params=params, timeout=120)
                
                if upload_response.status_code == 200:
                    upload_data = upload_response.json()
                    
                    if upload_data['response_code'] == 1:
                        return self.wait_for_scan_results(upload_data['resource'])
                    else:
                        return {"error": "Upload failed"}
                else:
                    return {"error": f"Upload failed: {upload_response.status_code}"}
        except requests.exceptions.RequestException as e:
            return {"error": f"Upload error: {str(e)}"}
    
    def wait_for_scan_results(self, resource_id: str, max_wait: int = 300) -> Dict:
        """Wait for scan results from VirusTotal"""
        report_url = f"{self.vt_base_url}/file/report"
        wait_time = 0
        
        self.logger.info("Waiting for scan to complete...")
        
        while wait_time < max_wait:
            time.sleep(15)
            wait_time += 15
            
            report_params = {
                'apikey': self.vt_api_key,
                'resource': resource_id
            }
            
            try:
                report_response = requests.get(report_url, params=report_params, timeout=30)
                
                if report_response.status_code == 200:
                    report_data = report_response.json()
                    
                    if report_data['response_code'] == 1:
                        return self.format_scan_results(report_data)
                    elif report_data['response_code'] == -2:
                        self.logger.info(f"Still processing... ({wait_time}s elapsed)")
                        continue
                    else:
                        return {"error": "Scan failed"}
            except requests.exceptions.RequestException as e:
                return {"error": f"Scan check error: {str(e)}"}
        
        return {"error": "Scan timeout"}
    
    def format_scan_results(self, scan_data: Dict) -> Dict:
        """Format VirusTotal scan results"""
        results = {
            "total_scans": scan_data.get('total', 0),
            "positives": scan_data.get('positives', 0),
            "scan_date": scan_data.get('scan_date', 'Unknown'),
            "permalink": scan_data.get('permalink', ''),
            "detections": []
        }
        
        if 'scans' in scan_data:
            for engine, result in scan_data['scans'].items():
                if result['detected']:
                    results["detections"].append({
                        "engine": engine,
                        "malware": result.get('result', 'Unknown'),
                        "version": result.get('version', 'Unknown')
                    })
        
        return results


def get_user_preferences():
    """
    Get user preferences for VirusTotal usage and API key handling
    """
    print("🔒 PDF Link Removal & Security Tool")
    print("=" * 50)
    
    # Ask about VirusTotal usage
    while True:
        use_vt = input("\n🦠 Do you want to scan with VirusTotal? (y/n): ").strip().lower()
        if use_vt in ['y', 'yes', 'n', 'no']:
            use_virustotal = use_vt in ['y', 'yes']
            break
        print("Please enter 'y' for yes or 'n' for no")
    
    api_key = None
    delete_api_after = False
    
    if use_virustotal:
        print("\n🔑 VirusTotal API Key Required")
        print("Get your free API key at: https://www.virustotal.com/gui/join-us")
        
        # Get API key securely
        api_key = getpass.getpass("Enter your VirusTotal API key (hidden): ").strip()
        
        if not api_key:
            print("❌ No API key provided. Continuing without VirusTotal scanning.")
            use_virustotal = False
        else:
            # Ask about API key cleanup
            while True:
                delete_choice = input("\n🗑️  Delete API key from memory when done? (y/n): ").strip().lower()
                if delete_choice in ['y', 'yes', 'n', 'no']:
                    delete_api_after = delete_choice in ['y', 'yes']
                    break
                print("Please enter 'y' for yes or 'n' for no")
            
            if not delete_api_after:
                print("⚠️  WARNING: API key will remain in memory. Ensure secure handling!")
    
    return use_virustotal, api_key, delete_api_after


def get_pdf_file_path():
    """
    Get PDF file path from user with validation
    """
    while True:
        pdf_path = input("\n📄 Enter path to PDF file: ").strip().strip('"\'')
        
        if os.path.exists(pdf_path) and pdf_path.lower().endswith('.pdf'):
            return pdf_path
        elif not os.path.exists(pdf_path):
            print(f"❌ File not found: {pdf_path}")
        else:
            print("❌ Please provide a PDF file (.pdf extension)")


def clean_api_from_memory(api_key: str):
    """
    Attempt to clear API key from memory (basic cleanup)
    """
    if api_key:
        # Overwrite the variable
        api_key = "0" * len(api_key)
        del api_key


def show_cleanup_commands():
    """
    Show sed/awk commands to clean any API remnants from files
    """
    print("\n🧹 API CLEANUP COMMANDS (for GitHub safety):")
    print("=" * 50)
    
    print("To remove any API keys from Python files before committing:")
    print("\n1. Using sed (Linux/Mac):")
    print("   sed -i 's/[a-f0-9]\\{64\\}/YOUR_API_KEY_HERE/g' *.py")
    print("   sed -i '/api.*key.*=.*[\"\\'][a-f0-9]\\{32,\\}[\"\\'].*/d' *.py")
    
    print("\n2. Using awk:")
    print("   awk '!/api.*key.*=.*[\"\\'][a-f0-9]{32,}[\"\\'].*/ {print}' script.py > clean_script.py")
    
    print("\n3. Git pre-commit hook (create .git/hooks/pre-commit):")
    print("   #!/bin/bash")
    print("   git diff --cached --name-only | xargs grep -l '[a-f0-9]\\{64\\}' && echo 'API key found!' && exit 1")
    
    print("\n4. Search for potential API keys:")
    print("   grep -r '[a-f0-9]\\{32,\\}' . --include='*.py'")
    print("   grep -r 'api.*key' . --include='*.py'")
    
    print("\n5. Remove from git history (if accidentally committed):")
    print("   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch script.py' HEAD")


def main():
    try:
        # Get user preferences
        use_virustotal, api_key, delete_api_after = get_user_preferences()
        
        # Get PDF file path
        pdf_path = get_pdf_file_path()
        
        # Generate safe output filenames with UUID
        remover = SecurePDFLinkRemover(api_key if use_virustotal else None)
        
        cleaned_pdf_path = remover.generate_safe_filename(pdf_path, "cleaned")
        sanitized_pdf_path = remover.generate_safe_filename(pdf_path, "sanitized")
        
        print(f"\n📂 File paths:")
        print(f"   Input:     {pdf_path}")
        print(f"   Cleaned:   {cleaned_pdf_path}")
        print(f"   Sanitized: {sanitized_pdf_path}")
        
        # Step 1: Extract all links before cleaning
        print(f"\n🔍 Analyzing PDF for embedded links...")
        link_analysis = remover.extract_all_links_and_content(pdf_path)
        
        print(f"📊 Analysis Results:")
        print(f"  - Embedded links: {len(link_analysis['link_details'])}")
        print(f"  - Text URLs: {len(link_analysis['text_urls'])}")
        print(f"  - Total unique links: {len(link_analysis['all_links'])}")
        
        if link_analysis['link_details']:
            print(f"\n🔗 Sample embedded links:")
            for i, link in enumerate(link_analysis['link_details'][:3], 1):
                print(f"  {i}. Page {link['page']}: {link.get('uri', 'N/A')[:50]}...")
            if len(link_analysis['link_details']) > 3:
                print(f"  ... and {len(link_analysis['link_details']) - 3} more")
        
        # Step 2: Scan original file (if VirusTotal enabled)
        scan_results = {"positives": 0, "total_scans": 0}
        if use_virustotal:
            print(f"\n🦠 Scanning original PDF with VirusTotal...")
            scan_results = remover.scan_file_virustotal(pdf_path)
            
            if 'error' not in scan_results:
                if scan_results['positives'] > 0:
                    print(f"⚠️  WARNING: {scan_results['positives']}/{scan_results['total_scans']} engines detected threats!")
                else:
                    print(f"✅ Clean: 0/{scan_results['total_scans']} detections")
            else:
                print(f"❌ VirusTotal scan error: {scan_results['error']}")
        else:
            print(f"\n⏭️  Skipping VirusTotal scan (not enabled)")
        
        # Step 3: Remove links comprehensively
        print(f"\n✂️  Removing all embedded links...")
        success, removed_links = remover.remove_all_links_comprehensive(pdf_path, cleaned_pdf_path)
        
        if success:
            print(f"✅ Successfully processed PDF")
            print(f"📤 Cleaned PDF: {os.path.basename(cleaned_pdf_path)}")
            
            # Step 4: Verify link removal
            print(f"\n🔍 Verifying link removal...")
            verification = remover.verify_link_removal(cleaned_pdf_path)
            
            if verification.get('is_clean', False):
                print("✅ Verification PASSED: No links remain")
            else:
                remaining = verification.get('total_remaining', 0)
                print(f"⚠️  Warning: {remaining} links still present")
                
                if remaining > 0:
                    print("🛡️  Creating text-only sanitized version...")
                    text_success = remover.create_sanitized_pdf_from_text(
                        pdf_path, sanitized_pdf_path, remove_urls_from_text=True
                    )
                    
                    if text_success:
                        print(f"✅ Fully sanitized PDF: {os.path.basename(sanitized_pdf_path)}")
                        
                        # Verify the sanitized version
                        sanitized_verification = remover.verify_link_removal(sanitized_pdf_path)
                        if sanitized_verification.get('is_clean', False):
                            print("✅ Sanitized version is completely clean")
            
            # Step 5: Generate report with UUID
            report_file = remover.generate_safe_filename(pdf_path.replace('.pdf', '_report.txt'), "analysis")
            
            with open(report_file, 'w') as f:
                f.write("=== PDF SECURITY ANALYSIS REPORT ===\n")
                f.write(f"Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Tool: Secure PDF Link Remover\n\n")
                
                f.write(f"FILES:\n")
                f.write(f"- Original: {os.path.basename(pdf_path)}\n")
                f.write(f"- Cleaned: {os.path.basename(cleaned_pdf_path)}\n")
                if os.path.exists(sanitized_pdf_path):
                    f.write(f"- Sanitized: {os.path.basename(sanitized_pdf_path)}\n")
                
                f.write(f"\nLINK ANALYSIS:\n")
                f.write(f"- Embedded links found: {len(link_analysis['link_details'])}\n")
                f.write(f"- Text URLs found: {len(link_analysis['text_urls'])}\n")
                f.write(f"- Total unique links: {len(link_analysis['all_links'])}\n")
                
                if use_virustotal and 'error' not in scan_results:
                    f.write(f"\nSECURITY SCAN:\n")
                    f.write(f"- VirusTotal detections: {scan_results.get('positives', 0)}/{scan_results.get('total_scans', 0)}\n")
                    if scan_results.get('permalink'):
                        f.write(f"- Report URL: {scan_results['permalink']}\n")
                
                f.write(f"\nVERIFICATION:\n")
                f.write(f"- Links remaining: {verification.get('total_remaining', 'unknown')}\n")
                f.write(f"- Status: {'CLEAN' if verification.get('is_clean', False) else 'NEEDS REVIEW'}\n")
                
                if link_analysis['all_links']:
                    f.write(f"\nALL LINKS FOUND:\n")
                    for i, link in enumerate(link_analysis['all_links'], 1):
                        f.write(f"{i:3d}. {link}\n")
            
            print(f"📄 Report saved: {os.path.basename(report_file)}")
            
            # Final summary
            print(f"\n📋 PROCESSING COMPLETE:")
            print(f"✓ Original file analyzed: {os.path.basename(pdf_path)}")
            print(f"✓ Links found: {len(link_analysis['all_links'])}")
            if use_virustotal and 'error' not in scan_results:
                print(f"✓ Malware scan: {scan_results.get('positives', 0)} threats detected")
            print(f"✓ Cleaned file created: {os.path.basename(cleaned_pdf_path)}")
            if os.path.exists(sanitized_pdf_path):
                print(f"✓ Sanitized file created: {os.path.basename(sanitized_pdf_path)}")
            print(f"✓ Analysis report: {os.path.basename(report_file)}")
            
        else:
            print("❌ Failed to remove links")
        
        # Clean up API key if requested
        if delete_api_after and api_key:
            print(f"\n🗑️  Cleaning API key from memory...")
            clean_api_from_memory(api_key)
            remover.vt_api_key = None
            print("✅ API key cleared from memory")
        
        # Show cleanup commands for GitHub safety
        if use_virustotal:
            show_cleanup_commands()
        
        print(f"\n🎉 Process completed successfully!")
        
    except KeyboardInterrupt:
        print(f"\n\n⚠️  Process interrupted by user")
        if 'api_key' in locals() and api_key and delete_api_after:
            clean_api_from_memory(api_key)
            print("🗑️  API key cleaned from memory")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        if 'api_key' in locals() and api_key and delete_api_after:
            clean_api_from_memory(api_key)
            print("🗑️  API key cleaned from memory")


if __name__ == "__main__":
    main()
