import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../shared/models/models.dart';
import '../../../shared/services/company_service.dart';
import '../../../shared/services/premium_feature_service.dart';
import '../../subscription/screens/paywall_screen.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final CompanyService _companyService = CompanyService();
  final PremiumFeatureService _premiumFeatureService = PremiumFeatureService();
  final ImagePicker _picker = ImagePicker();
  Company? _company;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedLogoPath;
  late TextEditingController _logoPathController;

  @override
  void initState() {
    super.initState();
    _logoPathController = TextEditingController();
    _loadCompany();
  }

  @override
  void dispose() {
    _logoPathController.dispose();
    super.dispose();
  }

  Future<void> _loadCompany() async {
    try {
      final company = await _companyService.getCompany();
      setState(() {
        _company = company;
        _selectedLogoPath = company?.logoPath;
        _logoPathController.text = _selectedLogoPath ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading company settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final featureResult = await _premiumFeatureService.checkFeatureAccess(PremiumFeature.logoUpload);

    if (!featureResult.isAllowed) {
      _showPremiumFeatureDialog(featureResult);
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String logoDir = path.join(appDir.path, 'logos');

        await Directory(logoDir).create(recursive: true);

        final String fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.${path.extension(pickedFile.path).replaceAll('.', '')}';
        final String newPath = path.join(logoDir, fileName);

        await File(pickedFile.path).copy(newPath);

        setState(() {
          _selectedLogoPath = newPath;
          _logoPathController.text = newPath;
        });

        if (_formKey.currentState != null) {
          _formKey.currentState!.fields['logoPath']?.didChange(newPath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCompany() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      try {
        final values = _formKey.currentState!.value;
        final company = Company(
          id: _company?.id,
          name: values['name'],
          legalName: values['legalName'],
          address: values['address'],
          phone: values['phone'],
          email: values['email'],
          website: values['website'],
          taxId: values['taxId'],
          logoPath: values['logoPath'],
        );

        await _companyService.updateCompany(company);
        final updatedCompany = await _companyService.getCompany();
        setState(() {
          _company = updatedCompany;
          _selectedLogoPath = updatedCompany?.logoPath;
          _logoPathController.text = _selectedLogoPath ?? '';
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company settings saved successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving company settings: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showPremiumFeatureDialog(FeatureGateResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(result.title ?? 'Premium Feature'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.description ?? 'This feature requires a premium subscription.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upgrade to Premium to unlock this feature',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final purchaseResult = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PaywallScreen(
                      blockedFeature: result.blockedFeature,
                    ),
                  ),
                );
                if (purchaseResult == true) {
                  // Refresh the screen after successful purchase
                  _loadCompany();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: Text(result.actionText ?? 'Upgrade'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Company Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildCompanyInfoSection(),
                      const SizedBox(height: 20),
                      _buildContactInfoSection(),
                      const SizedBox(height: 60),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCompanyInfoSection() {
    return _buildSection(
      title: 'Company Information',
      icon: Icons.business_outlined,
      child: Column(
        children: [
          _buildFormField(
            name: 'name',
            icon: Icons.business_center_outlined,
            labelText: 'Company Name *',
            initialValue: _company?.name,
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            name: 'legalName',
            icon: Icons.business_outlined,
            labelText: 'Legal Name',
            helperText: 'Full legal business name',
            initialValue: _company?.legalName,
          ),
          const SizedBox(height: 20),
          _buildLogoSection(),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_mail_outlined,
      child: Column(
        children: [
          _buildFormField(
            name: 'address',
            icon: Icons.location_on_outlined,
            labelText: 'Address',
            initialValue: _company?.address,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            name: 'phone',
            icon: Icons.phone_outlined,
            labelText: 'Phone',
            initialValue: _company?.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            name: 'email',
            icon: Icons.email_outlined,
            labelText: 'Email',
            initialValue: _company?.email,
            keyboardType: TextInputType.emailAddress,
            validator: FormBuilderValidators.email(),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            name: 'website',
            icon: Icons.web_outlined,
            labelText: 'Website',
            initialValue: _company?.website,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            name: 'taxId',
            icon: Icons.receipt_long_outlined,
            labelText: 'Tax ID / EIN',
            helperText: 'Your business tax identification number',
            initialValue: _company?.taxId,
          ),
          const SizedBox(height: 20),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String name,
    IconData? icon,
    required String labelText,
    String? helperText,
    String? initialValue,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            labelText,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FormBuilderTextField(
            name: name,
            initialValue: initialValue,
            validator: validator,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This information will appear on your invoices and estimates.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: _isSaving ? null : _saveCompany,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Company Logo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            FutureBuilder<bool>(
              future: _premiumFeatureService.canUploadLogo(),
              builder: (context, snapshot) {
                final canUpload = snapshot.data ?? false;
                if (canUpload) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_selectedLogoPath != null && _selectedLogoPath!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                    ),
                    child: File(_selectedLogoPath!).existsSync()
                        ? Image.file(
                            File(_selectedLogoPath!),
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedLogoPath != null && _selectedLogoPath!.isNotEmpty
                                ? 'Logo selecionada'
                                : 'Selecione uma logo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (_selectedLogoPath != null && _selectedLogoPath!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              path.basename(_selectedLogoPath!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                        _selectedLogoPath != null && _selectedLogoPath!.isNotEmpty
                            ? Icons.edit_outlined
                            : Icons.add_photo_alternate_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _selectedLogoPath != null && _selectedLogoPath!.isNotEmpty
                            ? 'Alterar'
                            : 'Selecionar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecione uma imagem da galeria para usar como logo da empresa',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 0,
          child: FormBuilderTextField(
            name: 'logoPath',
            controller: _logoPathController,
            decoration: const InputDecoration.collapsed(hintText: ''),
            style: const TextStyle(fontSize: 0, height: 0),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}