plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.smart_irrigation"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // تفعيل ميزة Desugaring لحل مشكلة مكتبة الإشعارات
        isCoreLibraryDesugaringEnabled = true
        
        // رفع الإصدار لـ 11 لإزالة تحذيرات الـ obsolete
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // جعل كوتلن متوافقة مع إصدار الجافا المختار
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.smart_irrigation"
        // الحد الأدنى الموصى به لعمل الفايربيز والإشعارات بشكل مستقر
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // تفعيل MultiDex ضروري عند استخدام مكاتب Firebase كثيرة
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // للتجربة حالياً، نستخدم إعدادات الـ debug للتوقيع
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // المكتبة المسؤولة عن حل خطأ CheckAarMetadata
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    // مكتبات Firebase
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-analytics")
}
