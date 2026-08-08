import 'package:flutter/foundation.dart';

/// Registrador central de Licenças Open-Source do aplicativo VozLume.
///
/// Garante a conformidade legal para distribuição e inclusão de modelos neurais,
/// motores C++, fontes tipográficas e bibliotecas de terceiros no Flutter LicenseRegistry.
class AppLicenseRegistry {
  static bool _registered = false;

  /// Registra todas as licenças dos componentes open-source no [LicenseRegistry].
  static void registerLicenses() {
    if (_registered) return;
    _registered = true;

    LicenseRegistry.addLicense(() async* {
      // 1. Modelo Neural Faber (Piper / VITS)
      yield const LicenseEntryWithLineBreaks(
        ['Piper TTS / Faber VITS (Modelo Neural PT-BR)'],
        '''
MIT License

Copyright (c) Michael Hansen / Rhasspy (Piper TTS)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''',
      );

      // 2. Modelo Neural Supertonic 3
      yield const LicenseEntryWithLineBreaks(
        ['Supertonic 3 (Modelo Neural Multi-Estágio INT8)'],
        '''
MIT License

Copyright (c) 2025 Supertone Inc. / k2-fsa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''',
      );

      // 3. Engine C++ Sherpa-ONNX
      yield const LicenseEntryWithLineBreaks(
        ['Sherpa-ONNX (Next-gen Kaldi C++ Runtime)'],
        '''
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

Copyright 2023 k2-fsa (Dan Povey et al.)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
''',
      );

      // 4. espeak-ng (Dados de Conversão G2P)
      yield const LicenseEntryWithLineBreaks(
        ['espeak-ng (Phonetic Data & Language Rules)'],
        '''
GNU General Public License v3.0 / GNU Lesser General Public License v3.0

Copyright (c) eSpeak NG Authors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
''',
      );

      // 5. ONNX Runtime Engine
      yield const LicenseEntryWithLineBreaks(
        ['ONNX Runtime'],
        '''
MIT License

Copyright (c) Microsoft Corporation. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''',
      );

      // 6. Fonte Spectral
      yield const LicenseEntryWithLineBreaks(
        ['Spectral Font Family'],
        '''
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007

Copyright (c) 2017, Production Type (http://www.productiontype.com), with Reserved Font Name "Spectral".

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is available with a FAQ at: http://scripts.sil.org/OFL
''',
      );

      // 7. Fonte Archivo
      yield const LicenseEntryWithLineBreaks(
        ['Archivo Font Family'],
        '''
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007

Copyright (c) 2012, Omnibus-Type (http://www.omnibus-type.com|omnibus-type@omnibus-type.com), with Reserved Font Name "Archivo".

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is available with a FAQ at: http://scripts.sil.org/OFL
''',
      );

      // 8. Fonte Space Mono
      yield const LicenseEntryWithLineBreaks(
        ['Space Mono Font Family'],
        '''
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007

Copyright (c) 2016, Colophon Foundry (www.colophon-foundry.org), with Reserved Font Name "Space Mono".

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is available with a FAQ at: http://scripts.sil.org/OFL
''',
      );
    });
  }
}
