import CoreRuntime
import NftGalleryModule

enum GeneratedModuleRegistry {
    static func all() -> [ModuleManifest] {
        [
            NftGalleryManifest(),
        ]
    }
}
