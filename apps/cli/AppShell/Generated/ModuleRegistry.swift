import CoreRuntime
import NftGalleryModule

public enum GeneratedModuleRegistry {
    public static func all() -> [ModuleManifest] {
        [
            NftGalleryManifest(),
        ]
    }
}
