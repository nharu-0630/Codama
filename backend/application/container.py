from typing import Any

from infrastructure.repositories.area_repository import AreaRepository
from infrastructure.repositories.cell_repository import CellRepository
from infrastructure.repositories.embedding_repository import EmbeddingRepository
from infrastructure.repositories.post_repository import PostRepository
from infrastructure.repositories.prompt_repository import PromptRepository
from interfaces.area_repository import AreaRepositoryInterface
from interfaces.cell_repository import CellRepositoryInterface
from interfaces.embedding_repository import EmbeddingRepositoryInterface
from interfaces.post_repository import PostRepositoryInterface
from interfaces.prompt_repository import PromptRepositoryInterface


class DIContainer:
    """依存性注入コンテナ"""

    def __init__(self):
        self._singletons: dict[type, Any] = {}
        self._instances: dict[type, type] = {}

    def register(self, interface: type, implementation: type, singleton: bool = True):
        """インターフェースと実装クラスを登録"""
        if singleton:
            self._singletons[interface] = implementation
        else:
            self._instances[interface] = implementation

    def resolve(self, interface: type):
        """インターフェースから実装クラスを解決"""
        # シングルトンから解決を試行
        if interface in self._singletons:
            impl_class = self._singletons[interface]
            if not hasattr(impl_class, "_instance"):
                instance = self._create_instance(impl_class)
                setattr(impl_class, "_instance", instance)
            return getattr(impl_class, "_instance")

        # 新しいインスタンスを生成
        if interface in self._instances:
            impl_class = self._instances[interface]
            return self._create_instance(impl_class)

        raise ValueError(f"Interface {interface} is not registered")

    def _create_instance(self, impl_class: type) -> Any:
        """実装クラスからインスタンスを生成"""
        import inspect

        sig = inspect.signature(impl_class.__init__)
        params = sig.parameters

        kwargs = {}
        for param_name, param in params.items():
            if param_name == "self":
                continue

            # 型注釈から依存性を解決
            if (
                param.annotation in self._singletons
                or param.annotation in self._instances
            ):
                kwargs[param_name] = self.resolve(param.annotation)
            else:
                # デフォルト値を使用
                if param.default != inspect.Parameter.empty:
                    kwargs[param_name] = param.default

        return impl_class(**kwargs)


# グローバルコンテナインスタンス
container = DIContainer()

# すべての依存性を登録
container.register(AreaRepositoryInterface, AreaRepository)
container.register(CellRepositoryInterface, CellRepository)
container.register(PostRepositoryInterface, PostRepository)
container.register(EmbeddingRepositoryInterface, EmbeddingRepository)
container.register(PromptRepositoryInterface, PromptRepository)
